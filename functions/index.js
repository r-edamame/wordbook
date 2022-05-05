const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const express = require('express');
const cookieParser = require('cookie-parser');
const cors = require('cors');

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//  response.send("Hello from Firebase!");
// });

/*
 * {
 *   questionId: string,
 *   correct: bool
 * }
 */

const app = express();

app.use(cookieParser());
//app.use(cors());
app.use((req,res,next)=>{
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
    res.setHeader('Access-Control-Allow-Credentials', 'true');
    next();
});

app.options('*', (req,res)=>{
    res.sendStatus(200);
});

const getRandomQuestion = async uid=>{
    const random = Math.floor(Math.random() * 0xffffffff);
    let question = admin.firestore().collection(`users/${uid}/questions`).where('available', '==', true);

    const snap = await question.where('random', '>=', random).orderBy('random').limit(1).get();

    if (!snap.empty) return {...snap.docs[0].data(), id: snap.docs[0].id};

    const retry = await question.where('random', '<', random).orderBy('random', 'desc').limit(1).get();
    if (retry.empty) {
        return null;
    }
    return {...retry.docs[0].data(), id: retry.docs[0].id};
}

app.use((async (req,res,next) => {

    if ((!req.headers.authorization || !req.headers.authorization.startsWith('Bearer ')) &&
        !(req.cookies && req.cookies.__session)) {
        res.status(403).send('Unauthorized');
        return;
    }

    let idToken;
    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer ')) {
        console.log('Found "Authorization" header');
        // Read the ID Token from the Authorization header.
        idToken = req.headers.authorization.split('Bearer ')[1];
    } else if (req.cookies) {
        console.log('Found "__session" cookie');
        // Read the ID Token from cookie.
        idToken = req.cookies.__session;
    } else {
        // No cookie
        res.status(403).send('Unauthorized');
        return;
    }

    try {
        const decodedIdToken = await admin.auth().verifyIdToken(idToken);
        console.log('ID Token correctly decoded', decodedIdToken);
        req.user = decodedIdToken;
        next();
        return;
    } catch (error) {
        console.error('Error while verifying Firebase ID token:', error);
        res.status(403).send('Unauthorized');
        return;
    }

    res.status(500);
    res.send('some exception');
}));

app.get('/authorized', (req,res)=>{
    res.send(`Authorized: uid=${req.user.uid}`);
});

app.post('/answer', (req, res)=>{
    const questionId = req.body.questionId;
    const corrected = req.body.corrected;

    if (typeof questionId!=='string' || typeof corrected!=='boolean') {
        res.json({status: 'error', message: `questionId: ${questionId}, corrected: ${typeof corrected}`});
        res.json({status: 'error', message: 'must be set json body'});
    }

    (async ()=>{
        const question = await admin.firestore().collection(`users/${req.user.uid}/questions`).doc(questionId).get();


        if (corrected) {
            const sc = question.data().serialCorrectCount;
            const tc = question.data().totalCorrectCount;
            const available = sc+1 < 10;
            await question.ref.set({serialCorrectCount: sc+1, totalCorrectCount: tc+1, available: available}, {merge: true});
        } else {
            await question.ref.set({serialCorrectCount: 0}, {merge: true});
        }

        const nextQuestion = await getRandomQuestion(req.user.uid);
        if (nextQuestion==null) {
            throw new Error('問題がありません 追加してください');
        }
        res.json({status: 'ok', content: nextQuestion});
    })().catch(e=>{
        res.json({status: 'error', message: e.message});
    });
});

app.get('/randomQuestion', async (req,res)=>{
    try{
        const question = await getRandomQuestion(req.user.uid);

        if (question==null) {
            throw new Error('問題がありません 追加してください');
        }

        res.json({status: 'ok', content: question});
    } catch (e) {
        res.json({status: 'error', message: e.message});
    }
});

app.post('/newQuestion', (req,res)=>{

    const japanese = req.body.japanese;
    const english = req.body.english;
    const group = req.body.group;

    if (typeof japanese!=='string' || typeof english!=='string' || typeof group!=='string') {
        res.json({status: 'error', message: 'must be set json parameter'});
    }

    admin.firestore().collection(`/users/${req.user.uid}/questions`).add({
        japanese: japanese,
        english: english,
        group: group,
    }).then(()=>{
        res.json({status: 'ok', content: null});
    }).catch(e=>{
        res.json({status: 'error', message: e.message});
    });
});

exports.api = functions.region('asia-northeast1').https.onRequest(app);

exports.addExtraParamOnQuestions = functions.region('asia-northeast1').firestore.document('users/{userId}/questions/{questionId}')
    .onCreate((snap, context)=>{
        const random = Math.floor(Math.random() * 0xffffffff);
        const param = {
            random: random,
            serialCorrectCount: 0,
            totalCorrectCount: 0,
            available: true
        };
        return snap.ref.set(param, {merge: true});
    });
