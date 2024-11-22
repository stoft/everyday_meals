# everyday_meals

A simple meal planner for everyday use.

Live at [everyday-meals.pages.dev](https://everyday-meals.pages.dev/).

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

## State Management Strategy

- Server is source of truth for meal data
- RxDB used only for offline storage, not sync
- When online: UI changes go through WebSocket to server, then server updates come back to update UI and RxDB
- When offline: UI changes stored in RxDB
- On reconnection: Fetch fresh state from server
- Last write wins for conflict resolution (based on timestamp)
