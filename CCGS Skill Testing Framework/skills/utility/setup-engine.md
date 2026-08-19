# Skill Test Spec: /setup-engine

## Skill Summary

`/setup-engine` configures the project's engine, language, rendering backend,
physics engine, specialist agent assignments, and naming conventions by
populating `technical-preferences.md`. It accepts an optional engine argument
(e.g., `/setup-engine unity 6.3`). For each
section of `technical-preferences.md`, the skill presents a draft and asks
"May I write to `technical-preferences.md`?" before updating.

The skill also populates the specialist routing table (file extension → agent
mappings) based on the chosen engine. It has no director gates — configuration
is a technical utility task. The verdict is always COMPLETE when the file is
fully written.

---

## Static Assertions (Structural)

Verified automatically by `/skill-test static` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" collaborative protocol language before updating technical-preferences.md
- [ ] Has a next-step handoff (e.g., `/brainstorm` or `/start` depending on flow)

---

## Director Gate Checks

None. `/setup-engine` is a technical configuration skill. No director gates apply.

---

## Test Cases

### Case 1: Unity 6.3 LTS — Full engine configuration (mobile)

**Fixture:**
- `technical-preferences.md` contains only placeholders
- Engine argument provided: `unity 6.3`

**Input:** `/setup-engine unity 6.3`

**Expected behavior:**
1. Skill skips engine-selection step (argument provided)
2. Skill presents scripting backend options: IL2CPP vs Mono
3. User selects IL2CPP scripting backend
4. Skill drafts all engine sections: engine/language/rendering/physics fields,
   naming conventions (PascalCase for C#), specialist assignments
   (unity-specialist, unity-ui-specialist, unity-shader-specialist, etc.)
5. Skill populates the routing table: `.cs` → unity-specialist, `.shadergraph` →
   unity-shader-specialist, `.uxml` → unity-ui-specialist
6. Skill asks "May I write to `technical-preferences.md`?"
7. File is written after approval; verdict is COMPLETE

**Assertions:**
- [ ] Engine field is set to Unity 6 LTS (not a placeholder)
- [ ] Scripting backend field is set to IL2CPP
- [ ] Naming conventions are C#-appropriate (PascalCase)
- [ ] Routing table includes `.gd`, `.gdshader`, and `.tscn` entries
- [ ] Specialists are assigned (not placeholders)
- [ ] "May I write" is asked before writing
- [ ] Verdict is COMPLETE

---

### Case 2: Unity + C# — Unity-specific configuration

**Fixture:**
- `technical-preferences.md` contains only placeholders
- Engine argument provided: `unity`

**Input:** `/setup-engine unity`

**Expected behavior:**
1. Skill sets engine to Unity, language to C#
2. Naming conventions are C#-appropriate (PascalCase for classes, camelCase for fields)
3. Specialist assignments reference unity-specialist, csharp-specialist
4. Routing table: `.cs` → csharp-specialist, `.asmdef` → unity-specialist,
   `.unity` (scene) → unity-specialist
5. Skill asks "May I write to `technical-preferences.md`?" and writes on approval

**Assertions:**
- [ ] Engine field is set to Unity (the fixed engine of this edition)
- [ ] Language field is set to C#
- [ ] Naming conventions reflect C# conventions
- [ ] Routing table includes `.cs` and `.unity` entries
- [ ] Verdict is COMPLETE

---

---

### Case 4: Engine Already Configured — Offers to reconfigure specific sections

**Fixture:**
- `technical-preferences.md` has engine set to Unity 6 LTS with all fields populated
- No engine argument provided

**Input:** `/setup-engine`

**Expected behavior:**
1. Skill reads `technical-preferences.md` and detects fully configured engine (Unity 6 LTS)
2. Skill reports: "Engine already configured as Unity 6 LTS + IL2CPP"
3. Skill presents options: reconfigure all, reconfigure specific section only
   (Engine/Language, Naming Conventions, Specialists, Performance Budgets)
4. User selects "Reconfigure Performance Budgets only"
5. Only the performance budget section is updated; all other fields unchanged
6. Skill asks "May I write to `technical-preferences.md`?" and writes on approval

**Assertions:**
- [ ] Skill does NOT overwrite all fields when only a section update was requested
- [ ] User is offered section-specific reconfiguration
- [ ] Only the selected section is modified in the written file
- [ ] Verdict is COMPLETE

---

### Case 5: Director Gate Check — No gate; setup-engine is a utility skill

**Fixture:**
- Fresh project with no engine configured

**Input:** `/setup-engine unity 6.3`

**Expected behavior:**
1. Skill completes full engine configuration
2. No director agents are spawned at any point
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is COMPLETE without any gate check

---

## Protocol Compliance

- [ ] Presents draft configuration before asking to write
- [ ] Asks "May I write to `technical-preferences.md`?" before writing
- [ ] Respects engine argument when provided (skips selection step)
- [ ] Detects existing config and offers partial reconfigure
- [ ] Routing table is populated for all key file types for the chosen engine
- [ ] Verdict is COMPLETE after file is written

---

## Coverage Notes

- Unity 6 LTS + IL2CPP is the fully tested flow (Case 1); the Mono scripting backend
  variant follows the same flow with different scripting backend settings.
  This variant is not separately tested.
- The engine-version-specific guidance (e.g., the LLM knowledge gap warning
  from VERSION.md) is surfaced by the skill but not assertion-tested here.
- Performance budget defaults per engine are noted as engine-specific but
  exact default values are not assertion-tested.
