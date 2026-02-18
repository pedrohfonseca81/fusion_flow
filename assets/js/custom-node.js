import { LitElement, html, css } from "lit";

export class CustomNodeElement extends LitElement {
  static get styles() {
    return css`
      :host {
        display: flex;
        flex-direction: column;
        background: var(--node-bg, white);
        border: 2px solid var(--node-border, #e2e8f0);
        border-radius: 16px;
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
        cursor: pointer;
        min-width: 220px;
        min-height: 80px;
        height: auto;
        padding-bottom: 12px;
        box-sizing: border-box;
        position: relative;
        user-select: none;
        font-family: 'Inter', system-ui, -apple-system, sans-serif;
        transition: all 0.2s ease-in-out;
      }
      
      :host(:hover) {
        border-color: #6366f1;
        transform: translateY(-2px);
        box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
      }
      
      :host(.selected) {
        border-color: #4338ca;
        box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.2), 0 20px 25px -5px rgba(0, 0, 0, 0.1);
        transform: scale(1.02);
      }

      :host-context(.dark) {
        --node-bg: #1e293b;
        --node-border: #334155;
        --node-text: #e2e8f0;
        --node-title-text: #f8fafc;
        box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.5), 0 4px 6px -2px rgba(0, 0, 0, 0.3);
      }
      :host-context(.dark):host(:hover) {
        border-color: #818cf8;
      }
      :host-context(.dark):host(.selected) {
        border-color: #6366f1;
        box-shadow: 0 0 0 4px rgba(99, 102, 241, 0.3), 0 20px 25px -5px rgba(0, 0, 0, 0.5);
      }

      :host(.error) {
        border-color: #ef4444 !important;
        box-shadow: 0 0 0 4px rgba(239, 68, 68, 0.2), 0 20px 25px -5px rgba(0, 0, 0, 0.1);
      }

      :host-context(.dark):host(.error) {
        border-color: #ef4444 !important;
        box-shadow: 0 0 0 4px rgba(239, 68, 68, 0.3), 0 20px 25px -5px rgba(0, 0, 0, 0.5);
      }

      .title {
        font-size: 15px;
        font-weight: 700;
        color: var(--node-title-text, #1e293b);
        padding: 12px 16px;
        text-transform: none;
        border-bottom: 1px solid var(--node-border, #e2e8f0);
        margin-bottom: 12px;
        background: linear-gradient(to bottom, rgba(255,255,255,0.5), rgba(255,255,255,0));
        border-radius: 14px 14px 0 0;
        letter-spacing: -0.01em;
      }
      :host-context(.dark) .title {
        background: linear-gradient(to bottom, rgba(255,255,255,0.05), rgba(255,255,255,0));
      }

      .remove-btn {
          position: absolute;
          top: -10px;
          right: -10px;
          background: #ef4444;
          color: white;
          border: 2px solid white;
          border-radius: 50%;
          width: 24px;
          height: 24px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          font-weight: bold;
          font-size: 14px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          z-index: 10;
          transition: transform 0.2s;
      }
      .remove-btn:hover {
          transform: scale(1.1);
          background: #dc2626;
      }

      .code-icon-btn {
          position: absolute;
          top: -10px;
          right: 20px;
          background: #4338ca;
          color: white;
          border: 2px solid white;
          border-radius: 50%;
          width: 24px;
          height: 24px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          font-weight: bold;
          font-size: 10px;
          box-shadow: 0 2px 4px rgba(0,0,0,0.1);
          z-index: 9;
          transition: transform 0.2s;
      }
      .code-icon-btn:hover {
          transform: scale(1.1);
          background: #3730a3;
      }
      
      div[data-testid^="control-"] {
          padding: 4px 8px;
      }

      .output {
        text-align: right;
        margin: 8px 0;
        padding-right: 12px;
        position: relative;
        display: flex;
        justify-content: flex-end;
        align-items: center;
        min-height: 24px;
      }
      .input {
        text-align: left;
        margin: 8px 0;
        padding-left: 12px;
        position: relative;
        display: flex;
        align-items: center;
        min-height: 24px;
      }
      .input-title {
        font-size: 13px;
        font-weight: 500;
        color: var(--node-text, #333);
        margin-left: 8px;
        line-height: 1.2;
      }
      .output-title {
         font-size: 13px;
         font-weight: 500;
         color: var(--node-text, #333);
         margin-right: 8px;
         line-height: 1.2;
      }
      
      .settings-btn {
          position: absolute;
          top: -10px;
          right: 20px;
          background: var(--color-primary, #6366f1);
          color: white;
          border: 2px solid var(--node-bg, white);
          border-radius: 50%;
          width: 28px;
          height: 28px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          z-index: 15;
          transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      }
      
      :host-context(.dark) .settings-btn {
          border-color: var(--node-bg, #18181b);
      }

      .settings-btn:hover {
          transform: scale(1.1) rotate(45deg);
          box-shadow: 0 6px 8px rgba(0,0,0,0.15);
      }
      
      .error-btn {
          position: absolute;
          top: -10px;
          right: 50px;
          background: #ef4444;
          color: white;
          border: 2px solid var(--node-bg, white);
          border-radius: 50%;
          width: 28px;
          height: 28px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
          box-shadow: 0 4px 6px rgba(0,0,0,0.1);
          z-index: 15;
          animation: pulse 2s infinite;
          transition: transform 0.2s;
      }
      
      .error-btn:hover {
          transform: scale(1.1);
          background: #dc2626;
      }
      
      @keyframes pulse {
        0% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0.7); }
        70% { box-shadow: 0 0 0 6px rgba(239, 68, 68, 0); }
        100% { box-shadow: 0 0 0 0 rgba(239, 68, 68, 0); }
      }

      .output-socket {
        position: absolute;
        right: -12px;
        top: calc(50% - 12px);
        margin: 0;
        z-index: 20;
      }
      
      .input-socket {
        position: absolute;
        left: -12px;
        top: calc(50% - 12px);
        margin: 0;
        z-index: 20;
      }
      .content {
        flex: 1;
        display: flex;
        flex-direction: column;
        justify-content: center;
        width: 100%;
      }
    `;
  }

  static get properties() {
    return {
      data: { type: Object },
      emit: { attribute: false },
      selected: { type: Boolean, reflect: true },
      onConfig: { attribute: false },
      error: { type: String, reflect: true },
      onErrorDetails: { attribute: false },
      onControlChange: { attribute: false }
    };
  }

  render() {
    const inputs = Object.entries(this.data.inputs);
    const outputs = Object.entries(this.data.outputs);
    const controls = Object.entries(this.data.controls).filter(([key, control]) => {
      if (control.type === 'hidden') return false;
      if (['code_elixir', 'code_python', 'input'].includes(key)) return false;
      return true;
    });

    return html`
        <div 
          class="remove-btn" 
          @pointerdown=${(e) => e.stopPropagation()} 
          @click=${(e) => {
        e.stopPropagation();
        if (this.onDelete) this.onDelete();
      }}
          title="Remove Node"
        >×</div>

        <div 
            class="settings-btn"
            @pointerdown=${(e) => e.stopPropagation()}
            @click=${(e) => {
        e.stopPropagation();
        if (this.onConfig) this.onConfig();
      }}
            title="Configure Node"
        >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-4 h-4">
              <path fill-rule="evenodd" d="M11.078 2.25c-.917 0-1.699.663-1.85 1.567L9.05 4.889c-.02.12-.115.26-.297.348a7.493 7.493 0 00-.986.57c-.166.115-.334.126-.45.083L6.3 5.508a1.875 1.875 0 00-2.282.819l-.922 1.597a1.875 1.875 0 00.432 2.385l.84.692c.095.078.17.229.154.43a7.598 7.598 0 000 1.139c.015.2-.059.352-.153.43l-.841.692a1.875 1.875 0 00-.432 2.385l.922 1.597a1.875 1.875 0 002.282.818l1.019-.382c.115-.043.283-.031.45.082.312.214.641.405.985.57.182.088.277.228.297.35l.178 1.071c.151.904.933 1.567 1.85 1.567h1.844c.916 0 1.699-.663 1.85-1.567l.178-1.072c.02-.12.114-.26.297-.349.344-.165.673-.356.985-.57.167-.114.335-.125.45-.082l1.02.382a1.875 1.875 0 002.28-.819l.922-1.597a1.875 1.875 0 00-.432-2.385l-.84-.692c-.095-.078-.17-.229-.154-.43a7.614 7.614 0 000-1.139c-.016-.2.059-.352.153-.43l.84-.692c.708-.582.891-1.59.433-2.385l-.922-1.597a1.875 1.875 0 00-2.282-.818l-1.02.382c-.114.043-.282.031-.449-.083a7.49 7.49 0 00-.985-.57c-.183-.087-.277-.227-.297-.348l-.179-1.072a1.875 1.875 0 00-1.85-1.567h-1.843zM12 15.75a3.75 3.75 0 100-7.5 3.75 3.75 0 000 7.5z" clip-rule="evenodd" />
            </svg>
        </div>

        ${this.error ? html`
        <div 
            class="error-btn"
            @pointerdown=${(e) => e.stopPropagation()}
            @click=${(e) => {
          e.stopPropagation();
          if (this.onErrorDetails) this.onErrorDetails();
        }}
            title="Show Error Details"
        >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="w-4 h-4">
              <path fill-rule="evenodd" d="M9.401 3.003c1.155-2 4.043-2 5.197 0l7.355 12.748c1.154 2-.29 4.5-2.599 4.5H4.645c-2.309 0-3.752-2.5-2.598-4.5L9.4 3.003zM12 8.25a.75.75 0 01.75.75v3.75a.75.75 0 01-1.5 0V9a.75.75 0 01.75-.75zm0 8.25a.75.75 0 100-1.5.75.75 0 000 1.5z" clip-rule="evenodd" />
            </svg>
        </div>
        ` : ''}
        
        <div class="title" data-testid="title">${this.data.label}</div>
        
        <div class="content">
          ${controls.map(([key, control]) => html`
            <div class="control" data-testid="control-${key}">
              <custom-control
                .type=${control.type}
                .value=${control.value}
                .label=${control.label}
                .options=${control.options}
                .readonly=${control.readonly}
                .onChange=${(val) => {
            this.onControlChange && this.onControlChange(key, val);
            this.requestUpdate();
          }}
                .onClick=${() => control.onClick && control.onClick()}
              ></custom-control>
            </div>
          `)}

          ${outputs.map(([key, output]) => {
            const outputLabel = output.label || key;
            return html`
              <div class="output" data-testid="output-${key}">
                ${outputLabel !== 'exec' ? html`<span class="output-title">${outputLabel}</span>` : ''}
                <custom-socket 
                    .data=${{ payload: output }} 
                    class="output-socket"
                    @connected=${(e) => this.bindSocket(e.target, 'output', key)}
                ></custom-socket>
              </div>
          `})}

          ${inputs.map(([key, input]) => {
              const inputLabel = input.label || key;
              return html`
              <div class="input" data-testid="input-${key}">
                <custom-socket 
                    .data=${{ payload: input }} 
                    class="input-socket"
                    @connected=${(e) => this.bindSocket(e.target, 'input', key)}
                ></custom-socket>
                ${inputLabel !== 'exec' ? html`<div class="input-title">${inputLabel}</div>` : ''}
              </div>
          `})}
        </div>
        `;
  }

  updated() {
    const outputs = this.shadowRoot.querySelectorAll('.output custom-socket');
    outputs.forEach(el => {
      const parent = el.closest('.output');
      const keyDiv = parent.querySelector('.output-title');
      const key = parent.getAttribute('data-testid').replace('output-', '');
      if (key) {
        this.bindSocket(el, 'output', key);
      }
    });

    const inputs = this.shadowRoot.querySelectorAll('.input custom-socket');
    inputs.forEach(el => {
      const parent = el.closest('.input');
      const key = parent.getAttribute('data-testid').replace('input-', '');
      if (key) {
        this.bindSocket(el, 'input', key);
      }
    });
  }

  bindSocket(el, type, key) {
    if (el && this.data && this.emit) {
      this.emit({
        type: 'render',
        data: {
          type: 'socket',
          element: el,
          payload: type === 'input' ? this.data.inputs[key] : this.data.outputs[key],
          side: type,
          key: key,
          nodeId: this.data.id
        }
      });
    }
  }
}
