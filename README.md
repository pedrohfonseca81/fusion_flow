# FusionFlow

**FusionFlow** is a powerful, low-code workflow automation platform equipped with advanced no-code capabilities. Designed for reliability and scalability, it enables users to visually design, manage, and execute complex business logic and data processing flows in real-time.

Whether you are automating simple tasks or orchestrating complex microservices, FusionFlow provides the visual tools to build without boundaries.

## ✨ Features

- **Visual Workflow Editor**: Intuitive drag-and-drop interface to build flows effortlessly.
- **Robust Execution**: Engines designed for fault tolerance and massive concurrency, ensuring your workflows run reliably under any load.
- **Real-time Synchronization**: collaborate with your team and see changes instantly.
- **Extensible Node System**:
  - **Flow Control**: Condition, Merge, SplitInBatches, Start.
  - **Integrations**: HTTP Request, Postgres, Webhook, and more coming soon.
  - **Logic**: Execute custom logic safely.
  - **Utilities**: Logger, Cron triggers.
- **Polyglot Potential**: Built to eventually support multiple languages (Python, JavaScript) for custom logic.
- **Dark Mode**: Fully styled interface for any lighting condition.

## 🚀 Getting Started

### Prerequisites

- Elixir ~> 1.15, Erlang/OTP 26+, PostgreSQL, Node.js
- OpenAI API Key (for AI features)

### Installation (Source)

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/pedrohfonseca81/fusion_flow.git
    cd fusion_flow
    ```

2.  **Install dependencies:**
    ```bash
    mix setup
    ```

3.  **Start the server:**
    ```bash
    mix phx.server
    ```

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

### Installation (Docker)

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/pedrohfonseca81/fusion_flow.git
    cd fusion_flow
    ```

2.  **Start with Docker Compose:**
    ```bash
    docker compose up -d --build
    ```
    This command will automatically:
    - Build the application image.
    - Start the database (Postgres).
    - Run necessary migrations.
    - Start the server.

3.  **Access the application:**
    Visit [`localhost:4000`](http://localhost:4000).

## 🛠️ Contributing

We welcome contributions to FusionFlow! Whether you're fixing bugs, adding new node types, or improving documentation, your help is appreciated.

### How to Contribute

1.  **Fork the repository** on GitHub.
2.  **Clone your fork** locally.
3.  **Create a new branch** for your feature or fix:
    ```bash
    git checkout -b feature/my-new-feature
    ```
4.  **Make your changes**. Please follow the existing code style and ensure tests pass.
5.  **Commit your changes** with clear, descriptive messages.
6.  **Push to your fork**:
    ```bash
    git push origin feature/my-new-feature
    ```
7.  **Open a Pull Request** against the `main` branch of the original repository.

### Development Guidelines

-   **Node Development**: New nodes should be added to `lib/fusion_flow/nodes/`. Follow the structure of existing nodes (separated `definition/0` and `handler/2`).
-   **UI Components**: We use Phoenix LiveView for the UI. Ensure any new JS components in `assets/js` are properly integrated via hooks.
-   **Testing**: Run `mix test` to ensure no regressions.

## 📝 TO-DO / Roadmap

The following features are planned for future releases:

- [x] **Visual Flow Execution**:
    - [x] **Run Button**: Execute flows directly from the editor.
    - [x] **Real-time Feedback**: Visual error highlighting and execution results.
    - [x] **Execution Persistence**: Log execution context to Postgres via `Output` node.

- [x] **Developer Experience**:
    - [x] **Variable Node**: Define and use global variables easy.
    - [x] **Smart Autocomplete**: Context-aware variable suggestions in code editors.
    - [x] **Error Visualization**: Detailed error modals and node validation.
    - [x] **AI Assistant**: Embedded chat interface for assistance.

- [X] **Multi-Language Runtime Support**:
    - [X] **Python Runner**: Execute Python scripts natively within flows.
    - [ ] **JavaScript/Node.js Runner**: Run JS code for logic and data manipulation.

- [ ] **Enhanced Real-time Collaboration**:
    - [ ] **Live Cursors**: See where other users are working in real-time.
    - [ ] **Presence Indicators**: Visual list of currently active users.
    - [ ] **Comments & Annotations**: Add sticky notes to the canvas for team communication.

- [ ] **Execution Engine Integration**:
    - [ ] Integrate [Oban](https://github.com/sorentwo/oban) for reliable background job processing.
    - [ ] Add support for "awaiting" asynchronous events (e.g., Webhook callbacks).

- [ ] **Dynamic Supervision**:
    - [ ] Implement supervisors to isolate running flows.
    - [ ] Add "Stop/Pause" functionality for running flows.

- [ ] **Expanded Node Library**:
    - [ ] **Productivity**: Google Sheets, Notion, Airtable, Slack, Discord.
    - [ ] **Communication**: SendGrid, Twilio (SMS), SMTP.
    - [ ] **Data & Helpers**: JSON Transform (JQ), CSV Parser, XML/SOAP Helpers, Regex Extractor.
    - [ ] **File I/O**: S3 Bucket, FTP/SFTP, Local File System.

- [ ] **Workflow Management**:
    - [ ] **Versioning**: History, snapshots, and rollback capabilities.
    - [ ] **AI Agents**: Native AI agents with state and supervision.

- [ ] **Authentication & Authorization**:
    - [ ] Multi-user support with `phx_gen_auth`.
    - [ ] Role-based access control (RBAC) for editing flows vs. viewing logs.

- [ ] **Monitoring & Analytics**:
    - [ ] Dashboard for execution metrics (success/failure rates, duration).

- [ ] **Deployment & Distribution**:
    - [ ] **Official Docker Image**: Publish to Docker Hub.

## License

FusionFlow is open-source software licensed under the [MIT license](LICENSE).
