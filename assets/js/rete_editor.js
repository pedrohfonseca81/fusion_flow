import { NodeEditor, ClassicPreset } from "rete";
import { AreaPlugin, AreaExtensions } from "rete-area-plugin";
import { ConnectionPlugin, Presets as ConnectionPresets } from "rete-connection-plugin";
import { LitPlugin, Presets } from "@retejs/lit-plugin";
import { html } from "lit";

import { CustomNodeElement } from "./custom-node.js";
import { CustomConnectionElement } from "./custom-connection.js";
import { CustomSocketElement } from "./custom-socket.js";
import { addCustomBackground } from "./custom-background.js";

import { CustomControlElement } from "./custom-control.js";

if (!customElements.get("custom-node")) {
    customElements.define("custom-node", CustomNodeElement);
}
if (!customElements.get("custom-connection")) {
    customElements.define("custom-connection", CustomConnectionElement);
}
if (!customElements.get("custom-socket")) {
    customElements.define("custom-socket", CustomSocketElement);
}
if (!customElements.get("custom-control")) {
    customElements.define("custom-control", CustomControlElement);
}

export async function createEditor(container) {
    const socket = new ClassicPreset.Socket("socket");

    const editor = new NodeEditor();
    const area = new AreaPlugin(container);
    const connection = new ConnectionPlugin();
    const render = new LitPlugin();

    AreaExtensions.selectableNodes(area, AreaExtensions.selector(), {
        accumulating: AreaExtensions.accumulateOnCtrl(),
    });

    render.addPreset(
        Presets.classic.setup({
            customize: {
                node(data) {
                    return ({ emit }) =>
                        html`<custom-node 
                .data=${data.payload} 
                .emit=${emit} 
                class="${data.payload.selected ? 'selected' : ''}"
                .onDelete=${async () => {
                                const nodeId = data.payload.id;
                                const connections = editor.getConnections();
                                for (const conn of connections) {
                                    if (conn.source === nodeId || conn.target === nodeId) {
                                        await editor.removeConnection(conn.id);
                                    }
                                }
                                await editor.removeNode(nodeId);
                            }}
                .onConfig=${() => {
                                if (editor.triggerNodeConfig) {
                                    const node = data.payload;
                                    const cleanData = {
                                        id: node.id,
                                        label: node.label,
                                        controls: {}
                                    };

                                    if (node.controls) {
                                        Object.entries(node.controls).forEach(([key, control]) => {
                                            cleanData.controls[key] = {
                                                value: control.value,
                                                label: control.label || key,
                                                type: control.type || 'text',
                                                options: control.options || []
                                            };
                                        });
                                    }

                                    editor.triggerNodeConfig(node.id, cleanData);
                                }
                            }}
                .onErrorDetails=${() => {
                                if (editor.triggerErrorDetails) {
                                    const node = data.payload;
                                    const view = area.nodeViews.get(node.id);
                                    let message = "Error details not available";
                                    if (view && view.element) {
                                        const customNode = view.element.querySelector('custom-node');
                                        if (customNode && customNode.error) {
                                            message = customNode.error;
                                        }
                                    }
                                    editor.triggerErrorDetails(node.id, message);
                                }
                            }}
                            }}
                .onControlChange=${(key, value) => {
                                if (editor.triggerChange) {
                                    const node = data.payload;
                                    if (node.controls[key]) {
                                        node.controls[key].value = value;
                                        editor.triggerChange();
                                    }
                                }
                            }}
            ></custom-node>`;
                },
                connection() {
                    return (props) =>
                        html`<custom-connection .path=${props.path}></custom-connection>`;
                },
                socket(data) {
                    return () => html`<custom-socket .data=${data} slot="${data.side}-${data.key}"></custom-socket>`;
                },
            },
        })
    );

    connection.addPreset(ConnectionPresets.classic.setup());

    addCustomBackground(area);

    editor.use(area);
    area.use(connection);
    area.use(render);

    AreaExtensions.simpleNodesOrder(area);

    const processChange = () => {
        if (editor.triggerChange) editor.triggerChange();
    };

    editor.addPipe(context => {
        if (
            context.type === 'nodecreated' ||
            context.type === 'noderemoved' ||
            context.type === 'connectioncreated' ||
            context.type === 'connectionremoved' ||
            context.type === 'translated'
        ) {
            processChange();
        }
        return context;
    });

    const processAddNode = async (name, definition, data = null) => {
        if (!definition) {
            console.error("Node definition not provided for", name);
            return;
        }

        const node = new ClassicPreset.Node(definition.name);
        node.type = definition.name;

        if (data && data.id) {
            node.id = data.id;
        }
        if (data && data.label) {
            node.label = data.label;
        }

        console.log("Adding node:", name, definition);

        if (definition.inputs) {
            definition.inputs.forEach(inputName => {
                node.addInput(inputName, new ClassicPreset.Input(socket));
            });
        }

        if (definition.outputs) {
            definition.outputs.forEach(outputName => {
                node.addOutput(outputName, new ClassicPreset.Output(socket));
            });
        }

        const uiFields = definition.ui_fields || [];

        uiFields.forEach(field => {
            const initialValue = (data && data.controls && data.controls[field.name]) || field.default || "";
            const control = new ClassicPreset.InputControl("text", { initial: initialValue });
            control.value = initialValue;

            if (field.type === 'code') {
                const renderMode = field.render || 'icon';

                if (renderMode === 'button') {
                    control.type = 'code-button';
                } else {
                    control.type = 'code-icon';
                }
                control.label = field.label || 'Edit Code';

                control.language = field.language || 'elixir';

                control.onClick = () => {
                    if (editor.triggerCodeEdit) {
                        const getUpstreamVariables = (startNodeId) => {
                            const variables = new Set();
                            const visited = new Set();
                            const queue = [startNodeId];

                            while (queue.length > 0) {
                                const currentId = queue.shift();
                                if (visited.has(currentId)) continue;
                                visited.add(currentId);

                                const currentNode = editor.getNode(currentId);
                                if (!currentNode) continue;

                                if ((currentNode.type === 'Variable' || currentNode.label === 'Variable') && currentNode.id !== startNodeId) {
                                    const varName = currentNode.controls.var_name?.value;
                                    if (varName) variables.add(varName);
                                }

                                const connections = editor.getConnections().filter(c => c.target === currentId);
                                for (const conn of connections) {
                                    queue.push(conn.source);
                                }
                            }
                            return Array.from(variables);
                        };

                        const language = node.controls.language?.value || control.language;
                        const code_elixir = node.controls.code_elixir?.value || '';
                        const code_python = node.controls.code_python?.value || '';
                        const variables = getUpstreamVariables(node.id);
                        editor.triggerCodeEdit(node.id, code_elixir, code_python, field.name, language, variables);
                    }
                };
            } else {
                control.type = field.type === 'select' ? 'select' : 'text';
                control.label = field.label;
                if (field.options) control.options = field.options;
            }

            node.addControl(field.name, control);
        });

        // Restore code_elixir and code_python controls if they exist in saved data
        if (data && data.controls) {
            if (data.controls.code_elixir !== undefined && !node.controls.code_elixir) {
                const ctrl = new ClassicPreset.InputControl("text", { initial: data.controls.code_elixir });
                ctrl.value = data.controls.code_elixir;
                ctrl.type = 'hidden';
                node.addControl('code_elixir', ctrl);
            }
            if (data.controls.code_python !== undefined && !node.controls.code_python) {
                const ctrl = new ClassicPreset.InputControl("text", { initial: data.controls.code_python });
                ctrl.value = data.controls.code_python;
                ctrl.type = 'hidden';
                node.addControl('code_python', ctrl);
            }
        }

        await editor.addNode(node);

        if (data && data.position) {
            await area.translate(node.id, data.position);
        }

        return node;
    };

    return {
        destroy: () => area.destroy(),
        addNode: async (name, definition, data = null) => {
            return await processAddNode(name, definition, data);
        },
        importData: async ({ nodes, connections, definitions }) => {
            console.log("ReteEditor: Importing data...", { nodes, connections });
            await editor.clear();

            for (const nodeData of nodes) {
                // Use type if available, otherwise fallback to label (legacy support)
                const nodeType = nodeData.type || nodeData.label;
                const definition = definitions[nodeType];

                if (!definition) {
                    console.warn(`Definition not found for node type: ${nodeType}`);
                    continue;
                }
                console.log(`ReteEditor: Restoring node ${nodeData.label} (${nodeData.id})`);
                await processAddNode(nodeType, definition, nodeData);
            }

            for (const connData of connections) {
                const sourceNode = editor.getNode(connData.source);
                const targetNode = editor.getNode(connData.target);

                if (sourceNode && targetNode) {
                    try {
                        await editor.addConnection(
                            new ClassicPreset.Connection(
                                sourceNode,
                                connData.sourceOutput,
                                targetNode,
                                connData.targetInput
                            )
                        );
                    } catch (e) {
                        console.error("Failed to restore connection:", connData, e);
                    }
                } else {
                    console.warn("Source or Target node not found for connection:", connData);
                }
            }

            if (nodes.length > 0) {
                AreaExtensions.zoomAt(area, editor.getNodes());
            }
        },

        onChange: (cb) => {
            editor.triggerChange = cb;
        },
        onCodeEdit: (cb) => {
            editor.triggerCodeEdit = cb;
        },
        onNodeConfig: (cb) => {
            editor.triggerNodeConfig = cb;
        },
        onErrorDetails: (cb) => {
            editor.triggerErrorDetails = cb;
        },
        updateNodeCode: async (nodeId, code_elixir, code_python, fieldName) => {
            const node = editor.getNode(nodeId);
            if (!node) return;

            if (!node.controls.code_elixir) {
                node.controls.code_elixir = { value: '' };
            }
            if (!node.controls.code_python) {
                node.controls.code_python = { value: '' };
            }

            node.controls.code_elixir.value = code_elixir;
            node.controls.code_python.value = code_python;

            await area.update('node', nodeId);
            processChange();
        },
        updateNodeData: async (nodeId, data) => {
            const node = editor.getNode(nodeId);
            if (!node) return;

            Object.entries(data).forEach(([key, value]) => {
                if (node.controls[key]) {
                    node.controls[key].value = value;
                }
            });

            await area.update('node', nodeId);
            processChange();
        },
        updateNodeLabel: async (nodeId, label) => {
            const node = editor.getNode(nodeId);
            if (!node) return;

            node.label = label;
            await area.update('node', nodeId);
            processChange();
        },
        updateNodeSockets: async (nodeId, { inputs, outputs }) => {
            const node = editor.getNode(nodeId);
            if (!node) return;

            // Update inputs
            const currentInputs = Object.keys(node.inputs);

            // Remove inputs that are no longer present
            for (const inputKey of currentInputs) {
                if (!inputs.includes(inputKey)) {
                    const connections = editor.getConnections().filter(c => c.target === nodeId && c.targetInput === inputKey);
                    for (const conn of connections) {
                        await editor.removeConnection(conn.id);
                    }
                    node.removeInput(inputKey);
                }
            }

            // Add new inputs
            for (const inputKey of inputs) {
                if (!node.inputs[inputKey]) {
                    node.addInput(inputKey, new ClassicPreset.Input(socket));
                }
            }

            // Update outputs
            const currentOutputs = Object.keys(node.outputs);

            // Remove outputs that are no longer present
            for (const outputKey of currentOutputs) {
                if (!outputs.includes(outputKey)) {
                    const connections = editor.getConnections().filter(c => c.source === nodeId && c.sourceOutput === outputKey);
                    for (const conn of connections) {
                        await editor.removeConnection(conn.id);
                    }
                    node.removeOutput(outputKey);
                }
            }

            // Add new outputs
            for (const outputKey of outputs) {
                if (!node.outputs[outputKey]) {
                    node.addOutput(outputKey, new ClassicPreset.Output(socket));
                }
            }

            await area.update('node', nodeId);
            processChange();
        },
        exportData: async () => {
            const nodes = [];
            const connections = [];

            for (const node of editor.getNodes()) {
                const controls = {};

                Object.keys(node.controls).forEach(key => {
                    controls[key] = node.controls[key].value;
                });

                nodes.push({
                    id: node.id,
                    type: node.type || node.label, // Use saved type, fallback to label
                    label: node.label,
                    controls,
                    position: area.nodeViews.get(node.id)?.position || { x: 0, y: 0 }
                });
            }

            for (const conn of editor.getConnections()) {
                connections.push({
                    source: conn.source,
                    sourceOutput: conn.sourceOutput,
                    target: conn.target,
                    targetInput: conn.targetInput
                });
            }

            return { nodes, connections };
        },
        addNodeError: (nodeId, message) => {
            console.log("ReteEditor: addNodeError called", { nodeId, message });
            const view = area.nodeViews.get(nodeId);
            console.log("ReteEditor: Found view?", view);
            if (view && view.element) {
                console.log("ReteEditor: Adding .error class to element", view.element);
                const customNode = view.element.querySelector('custom-node');
                if (customNode) {
                    customNode.classList.add('error');
                    customNode.error = message;
                } else {
                    // Fallback if custom-node is not found (should not happen with Lit render)
                    view.element.classList.add('error');
                }
                // Optional: Show message somehow? For now just border.
            } else {
                console.warn("ReteEditor: View or element not found for nodeId", nodeId);
            }
        },
        clearNodeErrors: () => {
            area.nodeViews.forEach(view => {
                if (view.element) {
                    view.element.classList.remove('error');
                    const customNode = view.element.querySelector('custom-node');
                    if (customNode) {
                        customNode.classList.remove('error');
                        customNode.error = null;
                    }
                }
            });
        },
    };
}
