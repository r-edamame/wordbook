
class WithHighlight extends HTMLElement {
    static get observedAttributes() {
        return ['color', 'text'];
    }

    attributeChangedCallback(attrName, oldVal, newVal) {
        this.highlight();
    }

    connectedCallback() {
        this.highlight();
    }

    highlight(text, _color) {
        const text = this.getAttribute('text');
        const color = this.getAttribute('color');

        const tohighlight = text.match(/<<(.*?)>>/g).map(e=>e.substr(2,e.length-4));
        const highlighted = tohighlight.reduce((txt,a)=>txt.replace(/<<(.*?)>>/, `<span style='color: ${color};'>${a}</span>`), text)

        this.innerHTML = highlighted;
    }
}

class HideAnswer extends HTMLElement {
    static get observedAttributes() {
        return ['text'];
    }

    attributeChangedCallback(attrName, oldVal, newVal) {
        this.hideText();
    }

    connectedCallback() {
        this.hideText();
    }

    hideText() {
        const text = this.getAttribute('text');
        const hidden = text.replace(/<<(.*?)>>/, '( )');
        this.innerHTML = hidden;
    }
}

customElements.define('with-highlight', WithHighlight);
customElements.define('hide-answer', HideAnswer);