
export class WithHighlight extends HTMLElement {
    static get observedAttributes() {
        return ['text', 'color'];
    }

    attributeChangedCallback() {
        const text = this.getAttribute('text') || "";
        const color = this.getAttribute('color');

        const matched = text.match(/<<(.*?)>>/g);

        let highlighted = text;
        if (matched===null) {
            console.log('nothing to highlight');
            highlighted = `<span style='color: ${color};'>${text}</span>`;
        } else {
            const tohighlight = matched.map(e=>e.substr(2,e.length-4));
            highlighted = tohighlight.reduce((txt,a)=>txt.replace(/<<(.*?)>>/, `<span style='color: ${color};'>${a}</span>`), text)
        }

        this.innerHTML = highlighted;
    }
}

export class HideAnswer extends HTMLElement {
    static get observedAttributes() {
        return ['text'];
    }

    attributeChangedCallback() {
        const text = this.getAttribute('text');

        const matched = text.match(/<<(.*?)>>/g);

        let hidden;

        if (matched===null) {
            console.log('nothing to hide');
            hidden = '( )';
        } else {
            hidden = text.replace(/<<(.*?)>>/, '( )');
        }

        this.innerHTML = hidden;
    }
}