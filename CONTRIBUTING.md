# Contributing to FusionFlow

We welcome contributions to FusionFlow! Whether you're fixing bugs, adding new node types, or improving documentation, your help is appreciated.

## How to Contribute

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

## Development Guidelines

-   **Node Development**: New nodes should be added to `lib/fusion_flow/nodes/`. Follow the structure of existing nodes (separated `definition/0` and `handler/2`).
-   **UI Components**: We use Phoenix LiveView for the UI. Ensure any new JS components in `assets/js` are properly integrated via hooks.
-   **Code Formatting**: Always run `mix format` before committing to maintain consistent code style.
-   **Testing**: Run `mix test` to ensure no regressions.
