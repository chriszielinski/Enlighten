hljs.initHighlightingOnLoad();

window.addEventListener('load', (event) => {
    document.body.style.marginTop='margin-top 0.1s';
    // Disable right-click context menu.
    document.body.setAttribute('oncontextmenu', 'event.preventDefault();');
});

/// Returns the scroll size of the document.
function htmlScrollSize() {
    var rect = document.documentElement.getBoundingClientRect();
    return [rect.width, rect.height];
}

/// Returns the width of the widest top-level element in the body of the document.
///
/// Based on [CodePen](https://codepen.io/anon/pen/YRWYbg) by Captain Anonymous.
function getWidthOfWidestElement() {
    // Get all body children.
    var list = document.body.children;
    // Convert pool of dom elements to array.
    var domElemArray = [].slice.call(list);

    // The width of the widest child.
    var widthOfWidestChild = 0;
    function compareChildWidth(child) {
        // Store original display value.
        var originalDisplayValue = child.style.display;
        // Set display to inline so the width "fits" the child's content.
        child.style.display = 'inline';

        if(child.offsetWidth > widthOfWidestChild) {
            // If this child is wider than the currently widest child, update the value.
            widthOfWidestChild = child.offsetWidth;
        }

        // Restore the original display value.
        child.style.display = originalDisplayValue;
    }

    // Call `compareItemWidth` on each child in `domElemArray`.
    domElemArray.forEach(compareChildWidth);
    // Return width of widest child.
    return widthOfWidestChild;
}

// Code below by Daniel Jalkut from https://indiestack.com/2018/10/supporting-dark-mode-in-app-web-content/
var darkModeStylesNodeID = "darkModeStyles";

function addStyleString(str, nodeID) {
    var node = document.createElement('style');
    node.id = nodeID;
    node.innerHTML = str;

    // Insert to HEAD before all others, so it will serve as a default, all other
    // specificity rules being equal. This allows clients to provide their own
    // high level body {} rules for example, and supersede ours.
    document.head.insertBefore(node, document.head.firstElementChild);
}

// For dark mode we impose CSS rules to fine-tune our styles for dark
function switchToDarkMode() {
    var darkModeStyleElement = document.getElementById(darkModeStylesNodeID);
    if (darkModeStyleElement == null) {
        var darkModeStyles = `
        body{color:#fff!important;}td,th{border:1px solid #222!important}a{color:#53c3ff!important}a:active,a:hover{color:#4aade3!important}h6{color:#BFBFBF!important}hr{border-bottom:1px solid #333!important}blockquote:before{color:#111!important}code{color:rgba(255,255,255,.75)!important}pre code{background-color:#000!important;color:#8C8C8C!important}kbd{color:#AAA!important;background-color:#030303!important;border:1px solid #333!important;border-bottom-color:#444!important;box-shadow:inset 0 -1px 0 #444!important}
        
        /* hljs */ .hljs{background:#1d1f21!important;color:#c5c8c6!important}.hljs span::selection,.hljs::selection{background:#373b41!important}.hljs span::-moz-selection,.hljs::-moz-selection{background:#373b41!important}.hljs-name,.hljs-title{color:#f0c674!important}.hljs-comment,.hljs-meta,.hljs-meta .hljs-keyword{color:#707880!important}.hljs-deletion,.hljs-link,.hljs-literal,.hljs-number,.hljs-symbol{color:#c66!important}.hljs-addition,.hljs-doctag,.hljs-regexp,.hljs-selector-attr,.hljs-selector-pseudo,.hljs-string{color:#b5bd68!important}.hljs-attribute,.hljs-code,.hljs-selector-id{color:#b294bb!important}.hljs-bullet,.hljs-keyword,.hljs-selector-tag,.hljs-tag{color:#81a2be!important}.hljs-subst,.hljs-template-tag,.hljs-template-variable,.hljs-variable{color:#8abeb7!important}.hljs-built_in,.hljs-builtin-name,.hljs-quote,.hljs-section,.hljs-selector-class,.hljs-type{color:#de935f!important}
        `;
        addStyleString(darkModeStyles, darkModeStylesNodeID);
    }
}

// For light mode we simply remove the dark mode styles to revert to default colors
function switchToLightMode() {
    var darkModeStyleElement = document.getElementById(darkModeStylesNodeID);
    if (darkModeStyleElement != null) {
        darkModeStyleElement.parentElement.removeChild(darkModeStyleElement);
    }
}
