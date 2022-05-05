
import * as custom from "./custom.js";

import {Elm} from "./Main.elm";
import {Elm as Login} from "./Home.elm";

import './style.scss';

const firebase = require('firebase/app');
require('firebase/auth');
require('firebase/firestore');


var firebaseConfig = {
    apiKey: "AIzaSyAcRS-L3I7jlQ7vcDTposeQwwVnfhMcjrY",
    authDomain: "elm-app-23184.firebaseapp.com",
    databaseURL: "https://elm-app-23184.firebaseio.com",
    projectId: "elm-app-23184",
    storageBucket: "elm-app-23184.appspot.com",
    messagingSenderId: "628214895393",
    appId: "1:628214895393:web:3bbc5978cd754634"
};
// Initialize Firebase
firebase.initializeApp(firebaseConfig);

firebase.auth().getRedirectResult().then(async result=>{
    
    let token = "";
    const user = firebase.auth().currentUser;

    if (user!=null) {
        token = await user.getIdToken();
    }

    const app = Elm.Main.init({
        flags: token
    });

    app.ports.auth.subscribe(()=>{
        firebase.auth().signInWithRedirect(new firebase.auth.TwitterAuthProvider());
    });

}).catch(error=>{
    console.warn(error);
});


customElements.define('with-highlight', custom.WithHighlight);
customElements.define('hide-answer', custom.HideAnswer);
