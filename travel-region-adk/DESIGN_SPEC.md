# DESIGN_SPEC.md

## Overview
`travel-region-adk` is a lightweight validation agent project for the travel support MVP.
It does not serve end users directly. Its job is to verify whether the codebase contains:

- sample region seed and residence filtering files
- lodging form template migration and storage structure
- Flutter lodging form editing screen
- FastAPI lodging-form PDF rendering endpoint

This validator must treat all current tourism region data as sample seed data unless explicit official integrations are added later.

## Example Use Cases
- "Check whether the residence-based region filtering files still exist."
- "Verify that lodging form template storage was added to the database."
- "Confirm that the mobile lodging form screen and FastAPI PDF route are both present."
- "Summarize which migrations are responsible for region and lodging-form behavior."

## Tools Required
- Local file inspection over:
  - `backend-spring/src/main/resources/db/migration`
  - `backend-spring/src/main/java`
  - `backend-fastapi/app`
  - `flutter_app/lib`
- No external API access is required for this validator.

## Constraints & Safety Rules
- Never claim sample seed data is official Korea Tourism Organization data.
- Only report what exists in the local repository.
- Clearly distinguish implemented behavior from TODO / placeholder behavior.
- Treat lodging form PDF rendering as an MVP placeholder renderer until real regional files are provided.

## Success Criteria
- The ADK project remains recognizable by `agents-cli info`.
- The validator can confirm whether:
  - region seed/residence filtering files exist
  - lodging template migration exists
  - lodging form Flutter screen exists
  - FastAPI PDF render route exists
- The validator can summarize the architecture without overstating production readiness.

## Reference Samples
- No strong sample dependency is required for this validator because it is a repo-local development helper.
