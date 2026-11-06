# Performance budgets

Measure with `devy-doctor --perf` (and `systemd-analyze blame` for boot). Fill in after each milestone.

| Metric | Target | VM (M1) | Victus (M2) | Notes |
|---|---|---|---|---|
| Boot to desktop | < 10 s | | | `systemd-analyze` + time to bar visible |
| Idle RAM (bar + notifications) | < 700 MB | | | `free -m` 1 min after login |
| Idle CPU | < 2 % | | | `btop` |
| zsh startup | < 50 ms | | | `devy-doctor --perf` |
| Battery drain at idle | — | n/a | | W from waybar battery tooltip |
