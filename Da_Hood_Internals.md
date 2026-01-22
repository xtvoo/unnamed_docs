# Da Hood Internals & Remotes

**Discovered via:** Recursive Remote Scanning (Juju & Unnamed Dumpers)
**Status:** Confirmed Active

## ⚡ Core Combat Remotes
These are the primary networking events used by the game engine. Scripting these directly allows for "Silent Aim", "Insta-Kill", and other high-performance features.

### `ReplicatedStorage.MainEvent`
**Type:** `RemoteEvent`
**Usage:** The "God Remote". Handles almost all combat interactions.
*   **Shooting:** Fires when a bullet is shot.
*   **Stomping:** Fires when stomping a knocked player.
*   **Melee:** Fires for punches/knife hits.

### `Remotes.SetBounty`
**Type:** `RemoteFunction`
**Usage:** Sets a bounty on a player.
*   *Note:* Often protected or requires server-side validation, but useful for bounty bots.

## 🛠️ Utility Remotes
| Name | Parent | Type | Description |
| :--- | :--- | :--- | :--- |
| `PurchasePrompt` | `Remotes` | `RemoteEvent` | Triggers the GUI for buying items (Ammo, Guns, Food). |
| `Handshake` | `Remotes` | `RemoteEvent` | likely Anti-Cheat or Server Synchronization. Avoid tampering unless necessary. |
| `TapBall` | `Remotes` | `RemoteEvent` | Interaction with the soccer ball minigame. |
| `MacroDisableVote` | `Remotes` | `RemoteEvent` | Voting system to kick laggy players/macro users? |

## 🌍 Global Environment (`getgenv`)
Key globals found in the environment that interact with these internals:
*   **`_JUJU` / `_UNNAMED`**: Internal state tables.
*   **`firesignal`**: Essential function for simulating local events (like `MouseClick`).
