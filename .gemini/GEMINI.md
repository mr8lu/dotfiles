# Global Personal Memory

## Global Agent Instructions:

- Never use the em dash "—". Use plain dash "-" instead
- When writing commit messages, NEVER auto-add your agent name as co-author
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- When making technical decisions, do not give much weight to development cost. Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible. This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection. If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness. If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- When performing a git push or shipping code changes, always use the 'no-mistakes' pipeline (or skill) to validate and automate the verification of changes before pushing them to any remote target

## Coding Preference:

- **ALWAYS** use changelog, commit often, update documentations when big changes occured.
- **Ensure** deployment documentations' coverage is whole and can be follow without issue (add pre-reqs if needed).

### Python

- ALWAYS use `uv` for virtual environment management

### Python Library Preferences

- Use PikePDF instead of PyMuPDF for PDF operations and AI solutions
- Utilize the Polars DataFrame library for Python when needed to optimize speed/quality


## Subagent and Environment Preference:

- **ALWAYS** default to using global subagents (`~/.gemini/agents/`) and only use project-level subdirectories (`.gemini/agents/`) when they are available and distinct from the global directory.
- **ALWAYS** prioritize Gemini CLI as the default agent harness and backend. Do not use Claude or Codex; all agentic tools and proxy gateways (such as Firstmate and `no-mistakes`) must be configured or shimmed to route through `gemini`.


## Writing

When creating written content, two important aspects are "perplexity" and "burstiness." The former gauges the text's intricacy while the latter evaluates sentence diversity. Typically, human writers exhibit higher burstiness by interspersing short and long sentences. In contrast, AI-generated sentences tend to be uniform in length. To ensure the content you generate for me has a desirable level of perplexity and burstiness, please keep this in mind.

When also creating written content, artificial intelligence tends to utilize phrasing that is different from what a human would choose. Utilize uncommon terminology to enhance the originality of the piece.

Please format the given content in a professional format and not an AI formaat.

Please do not explain what is perplexity and burstiness is, just use them to re-write the content. Please put this in your mind. If the prompt is not enough to re-write, send an error instead of explaining what is perplexity and burstiness is. Please mind this. If the prompt is insufficient, return an error with this format:



## MS Teams & Outlook Notification Tooling:

You have access to custom MS Teams and Outlook notification engines on macOS. Use them to notify the user of successful deployments, job completion, or important updates.

- **Programmatic Notification Engine (`~/notify-teams.sh`)**:
  - **Purpose**: Dispatches notifications via a JSON webhook POST request, or via Microsoft Outlook email (using AppleScript).
  - **Usage**:
    - Shortcut: `~/notify-teams.sh <project>:<effort>:<person> "<message>"`
    - Verbose: `~/notify-teams.sh -p <project> -e <effort> -r <person> -m "<message>" [-s <success|failure>]`
  - **Configuration Commands**:
    - Add/Update route: `~/notify-teams.sh --add <project>:<effort>:<person> "<url_or_email>"`
    - List routes: `~/notify-teams.sh --list`
    - Remove route: `~/notify-teams.sh --remove <project>:<effort>:<person>`
  - **How it routes**:
    - If the target endpoint contains `@`, it sends an email via MS Outlook using AppleScript.
    - Otherwise, it makes an HTTP POST request with a JSON payload to the registered Teams Webhook URL.

- **UI Automation Notification Engine (`~/notify-teams-ui.sh`)**:
  - **Purpose**: Opens direct MS Teams chats and automates sending the message via AppleScript GUI automation (System Events).
  - **Usage**:
    - Shortcut: `~/notify-teams-ui.sh <project>:<effort>:<person> "<message>"`
  - **Configuration Commands**:
    - Add/Update route: `~/notify-teams-ui.sh --add <project>:<effort>:<person> "<recipient_emails_comma_separated>"`
    - List routes: `~/notify-teams-ui.sh --list`
    - Remove route: `~/notify-teams-ui.sh --remove <project>:<effort>:<person>`
  - **How it routes**:
    - The target route must be one or more email addresses.
    - Opens the chat via deep link (`msteams://`) and simulates the Enter key after a short delay (requires Accessibility permissions on macOS).
