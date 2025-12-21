---
description: Context & Memory management for Antigravity - ALWAYS START HERE
---

# Antigravity Context Maintenance

> [!IMPORTANT]
> **MANDATORY FIRST STEPS**: Before ANY codebase_search or grep_search, you MUST complete steps 1-2. This is non-negotiable.

## Startup Sequence (Do This First!)

// turbo

1. **Read Memory FIRST**: `view_file docs/MEMORY.md` - Understand current state, goals, recent history.

// turbo
2. **Consult Architecture**: `view_file docs/ARCHITECTURE.md` - Technical constraints and system design.

// turbo
3. **Check Design Goals** (if relevant): `view_file docs/DESIGN.md` - Aesthetic and gameplay constraints.

**Only after completing the above** may you proceed with codebase searches or modifications.

---

## During Work

1. **Update Memory**: After implementing significant features, fixing bugs, or making architectural decisions, update `docs/MEMORY.md`.
2. **Follow Workflows**: Check `.agent/workflows/` for task-specific procedures.

// turbo-all

## Usage

This workflow is active by default for all "Pizak" project tasks. The agent should treat this as an implicit `/context` call at the start of every session.
