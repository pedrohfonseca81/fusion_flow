export const CodeEditorHook = {
    mounted() {
        const container = this.el;
        const elixirTextarea = container.querySelector('#code_elixir_textarea');
        const pythonTextarea = container.querySelector('#code_python_textarea');

        if (!elixirTextarea && !pythonTextarea) return;

        const editorContainer = document.createElement('div');
        editorContainer.style.height = '100%';
        editorContainer.style.width = '100%';
        editorContainer.style.minHeight = '400px';

        container.appendChild(editorContainer);

        const currentVariables = JSON.parse(container.dataset.variables || "[]");
        window.__fusionFlowCurrentVariables = currentVariables;

        const initMonaco = () => {
            if (window.require) {
                window.require.config({ paths: { 'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs' } });

                window.require(['vs/editor/editor.main'], () => {
                    if (!window.__elixirCompletionRegistered) {
                        try {
                            monaco.languages.registerCompletionItemProvider('elixir', {
                                provideCompletionItems: (model, position) => {
                                    const suggestions = [
                                        {
                                            label: 'variable',
                                            kind: monaco.languages.CompletionItemKind.Function,
                                            insertText: 'variable',
                                            documentation: 'Get a variable from context (returns nil if missing)',
                                            detail: 'FusionFlow.Nodes.Eval.variable/1'
                                        },
                                        {
                                            label: 'variable!',
                                            kind: monaco.languages.CompletionItemKind.Function,
                                            insertText: 'variable!',
                                            documentation: 'Get a variable from context (raises if missing)',
                                            detail: 'FusionFlow.Nodes.Eval.variable!/1'
                                        }
                                    ];

                                    const availableVars = window.__fusionFlowCurrentVariables || [];
                                    availableVars.forEach(varName => {
                                        suggestions.push({
                                            label: `:${varName}`,
                                            kind: monaco.languages.CompletionItemKind.Constant,
                                            insertText: `:${varName}`,
                                            documentation: `Variable from flow: ${varName}`,
                                            detail: 'Atom'
                                        });
                                    });

                                    return { suggestions: suggestions };
                                }
                            });
                            window.__elixirCompletionRegistered = true;
                        } catch (e) {
                            console.error("Failed to register completion provider:", e);
                        }
                    }

                    // Get initial language from data attribute
                    const currentLang = container.dataset.language || 'elixir';
                    const initialValue = currentLang === 'python'
                        ? (pythonTextarea ? pythonTextarea.value : '')
                        : (elixirTextarea ? elixirTextarea.value : '');

                    this.editor = monaco.editor.create(editorContainer, {
                        value: initialValue,
                        language: currentLang,
                        theme: 'vs-dark',
                        automaticLayout: true,
                        minimap: { enabled: false },
                        scrollBeyondLastLine: false,
                        fontSize: 14,
                        fontFamily: "'Fira Code', Consolas, 'Courier New', monospace"
                    });

                    // Store current language
                    this.currentLanguage = currentLang;

                    // Update the appropriate textarea when content changes
                    this.editor.onDidChangeModelContent(() => {
                        const value = this.editor.getValue();
                        if (this.currentLanguage === 'python' && pythonTextarea) {
                            pythonTextarea.value = value;
                            pythonTextarea.dispatchEvent(new Event('input', { bubbles: true }));
                        } else if (elixirTextarea) {
                            elixirTextarea.value = value;
                            elixirTextarea.dispatchEvent(new Event('input', { bubbles: true }));
                        }
                    });

                    // Watch for language changes via MutationObserver
                    this.observer = new MutationObserver((mutations) => {
                        mutations.forEach((mutation) => {
                            if (mutation.type === 'attributes' && mutation.attributeName === 'data-language') {
                                const newLang = container.dataset.language;
                                if (newLang !== this.currentLanguage) {
                                    // Save current content to appropriate textarea
                                    const currentValue = this.editor.getValue();
                                    if (this.currentLanguage === 'python' && pythonTextarea) {
                                        pythonTextarea.value = currentValue;
                                    } else if (elixirTextarea) {
                                        elixirTextarea.value = currentValue;
                                    }

                                    // Load new language content
                                    const newValue = newLang === 'python'
                                        ? (pythonTextarea ? pythonTextarea.value : '')
                                        : (elixirTextarea ? elixirTextarea.value : '');

                                    this.editor.setValue(newValue);
                                    monaco.editor.setModelLanguage(this.editor.getModel(), newLang);
                                    this.currentLanguage = newLang;
                                }
                            }
                        });
                    });

                    this.observer.observe(container, { attributes: true });
                });
            }
        };

        if (!window.require) {
            const script = document.createElement('script');
            script.src = 'https://cdn.jsdelivr.net/npm/monaco-editor@0.45.0/min/vs/loader.js';
            script.async = true;
            script.onload = initMonaco;
            document.body.appendChild(script);
        } else {
            initMonaco();
        }
    },

    updated() {
        // Update data-language attribute when tab changes
        const container = this.el;
        const newLang = container.dataset.language;

        if (this.editor && newLang && newLang !== this.currentLanguage) {
            const elixirTextarea = container.querySelector('#code_elixir_textarea');
            const pythonTextarea = container.querySelector('#code_python_textarea');

            // Save current content
            const currentValue = this.editor.getValue();
            if (this.currentLanguage === 'python' && pythonTextarea) {
                pythonTextarea.value = currentValue;
            } else if (elixirTextarea) {
                elixirTextarea.value = currentValue;
            }

            // Load new language content
            const newValue = newLang === 'python'
                ? (pythonTextarea ? pythonTextarea.value : '')
                : (elixirTextarea ? elixirTextarea.value : '');

            this.editor.setValue(newValue);
            monaco.editor.setModelLanguage(this.editor.getModel(), newLang);
            this.currentLanguage = newLang;
        }
    },

    destroyed() {
        if (this.observer) {
            this.observer.disconnect();
        }
        if (this.editor) {
            this.editor.dispose();
        }
    }
};
