---
trigger: always_on
---

# Context Maintenance Rule

Always follow these steps for every new session or task.

## Mandatory Startup Sequence

Before performing any codebase searches, grep searches, or code modifications, you MUST read the following files to establish context:

1. **Read Memory**: `view_file docs/MEMORY.md` - Understand current state, goals, recent history.
2. **Consult Architecture**: `view_file docs/ARCHITECTURE.md` - Technical constraints and system design.
3. **Check Design Goals**: `view_file docs/DESIGN.md` - Aesthetic and gameplay constraints.

Only after reading these documents should you proceed with task-specific searches or modifications.

## Continuous Context Maintenance

1. **Update Memory**: After implementing significant features, fixing bugs, or making architectural decisions, you must update `docs/MEMORY.md` to reflect the new state of the project.
2. **Consult Workflows**: Regularly check `.agent/workflows/` for project-specific procedures.
