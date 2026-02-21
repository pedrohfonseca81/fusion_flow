# FusionFlow

[![Discord](https://img.shields.io/discord/1342308064887373844?color=7289da&label=discord&logo=discord&logoColor=white)](https://discord.gg/7zjnpna239)

**FusionFlow** is a powerful, low-code workflow automation platform equipped with advanced no-code capabilities. Designed for reliability and scalability, it enables users to visually design, manage, and execute complex business logic and data processing flows in real-time.

Whether you are automating simple tasks or orchestrating complex microservices, FusionFlow provides the visual tools to build without boundaries.

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

## 🤝 Community & Contributing

We believe in building in public. Join our community to discuss ideas, track our vision, or help us build:

- **Contributing**: Check our [Contributing Guide](CONTRIBUTING.md) to get started.
- **Public Roadmap**: Long-term vision and goals on our [Roadmap Repository](https://github.com/FusionFlow-app/roadmap).
- **Project Board**: Live active tasks on our [GitHub Project Board](https://github.com/orgs/FusionFlow-app/projects/2).
- **Discord Server**: Real-time chat and support in our [Discord Server](https://discord.gg/7zjnpna239).

## License

FusionFlow is open-source software licensed under the [MIT license](LICENSE).
