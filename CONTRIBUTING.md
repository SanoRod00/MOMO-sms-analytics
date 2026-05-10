# Contributing to MOMO SMS Analytics

Thank you for contributing to this project. This document covers everything you need to go from zero to an open pull request.

---

## Table of Contents

1. [Setting up your environment](#setting-up-your-environment)
2. [Project structure](#project-structure)
3. [How to propose a change](#how-to-propose-a-change)
4. [Commit message convention](#commit-message-convention)
5. [Pull request expectations](#pull-request-expectations)
6. [Code review checklist](#code-review-checklist)
7. [Definition of Done](#definition-of-done)

---

## Setting up your environment

### Prerequisites
- Python 3.11+
- pip
- Git

### Steps

```bash
# 1. Clone the repository
git clone https://github.com/SanoRod00/MOMO-sms-analytics.git
cd MOMO-sms-analytics

# 2. Create and activate a virtual environment
python -m venv .venv
source .venv/bin/activate          # Linux / macOS
# .venv\Scripts\activate           # Windows

# 3. Install dependencies
pip install -r requirements.txt

# 4. Copy environment variables
cp .env.example .env
```

### Verify the setup

```bash
# Run the test suite
pytest

# Run the ETL pipeline (requires data/raw/momo.xml)
bash scripts/run_etl.sh

# Serve the frontend
bash scripts/serve_frontend.sh
# Open http://localhost:8000
```

See [docs/SETUP.md](./docs/SETUP.md) for detailed onboarding and common issues.

---

## Project structure

```
.
├── etl/          # ETL pipeline (parse → clean → categorize → load)
├── api/          # Optional FastAPI layer
├── web/          # Frontend assets (CSS, JS)
├── data/         # Raw input, SQLite DB, logs, dead-letter
├── tests/        # pytest test suite
├── scripts/      # Shell helpers
└── docs/         # Architecture, agile, and setup documentation
```

---

## How to propose a change

1. **Check the board** — look at the [Jira board](https://alustudent-team-elyjmvr5.atlassian.net/jira/software/projects/SCRUM/boards/1) to see if the work is already tracked. If not, create a card.

2. **Pull the latest `main`**
   ```bash
   git checkout main
   git pull origin main
   ```

3. **Create a branch** following the naming convention:
   ```
   feat/<short-description>    # new functionality
   fix/<short-description>     # bug fixes
   docs/<short-description>    # documentation only
   chore/<short-description>   # tooling, scripts, config
   ```
   Example: `git checkout -b feat/xml-parser`

4. **Make your changes** in small, focused commits (see convention below).

5. **Run tests** before pushing:
   ```bash
   pytest
   ```

6. **Push your branch** and open a pull request against `main`.

7. **Link your Jira card** in the PR description (e.g., `SCRUM-8`).

8. **Move your card to In Review** on the board.

---

## Commit message convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>: <short summary>
```

| Type | When to use |
|---|---|
| `feat` | New feature or functionality |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `chore` | Tooling, scripts, config — no production logic |
| `test` | Adding or updating tests |
| `refactor` | Code change that neither fixes a bug nor adds a feature |

**Examples:**
```
feat: add XML parser for incoming money transactions
fix: handle missing amount field in normalize step
docs: add architecture diagram to README
chore: add shebang and stub commands to shell scripts
test: add unit tests for categorize.py
```

Keep the summary under 72 characters. Use the imperative mood ("add", not "added" or "adds").

---

## Pull request expectations

- **Title** follows the same conventional commit format as your commits.
- **Description** includes:
  - A brief summary of what changed and why.
  - The Jira card number (e.g., `Closes SCRUM-8`).
  - Any manual testing steps a reviewer should follow.
- **Scope** — keep PRs focused. One concern per PR makes review faster and history cleaner.
- **At least one approval** is required before merging.
- The **PR author** merges their own PR after approval.
- **Delete the branch** after merge to keep the repository tidy.
- Move the Jira card to **Done** after the merge.

---

## Code review checklist

Reviewers verify the following before approving:

- [ ] The code runs locally without errors
- [ ] No secrets, API keys, or real personal data are committed
- [ ] New files are placed in the correct project folder
- [ ] Tests are added or updated where the logic changed
- [ ] The README or relevant docs are updated if behavior changed
- [ ] The PR title and description follow the conventions above

---

## Definition of Done

A contribution is complete when:

- [ ] Code is merged into `main`
- [ ] Related documentation is updated
- [ ] All tests pass
- [ ] No unresolved review comments remain
- [ ] The Jira card is moved to **Done**
- [ ] The feature branch is deleted

---

## Questions or blockers?

Post in the team WhatsApp group or tag a teammate in the relevant Jira card. The current Scrum Master (see [docs/AGILE.md](./docs/AGILE.md)) is responsible for clearing blockers.
