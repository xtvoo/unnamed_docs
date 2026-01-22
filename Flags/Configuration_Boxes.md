# Configuration Boxes (The "Box" System)

Unnamed organizes its configuration settings into specific global tables ending in `Box`. This differs from other cheats that use a flat list of flags.

**Access:** These tables are available in the global environment (`getgenv()`).

## ⚔️ Combat Configuration
| Box Name | Purpose | Key Settings (Likely) |
| :--- | :--- | :--- |
| **`RageBox`** | Main Ragebot Settings | `Enabled`, `FOV`, `TargetMode` |
| **`RageResolverBox`** | Anti-Desync / Resolver | `ResolveMode`, `Override` |
| **`VoidRageBox`** | "Void" Attack Settings | `TeleportToVoid`, `HoldTarget` |
| **`StompBox`** | Auto-Stomp Logic | `Enabled`, `Range`, `Delay` |
| **`GrenadeBox`** | Auto-Grenade Logic | `Enabled`, `Prediction` |
| **`NotifyHitBox`** | Hitmarker UI | `Enabled`, `Sound`, `Color` |
| **`NotifyDamageBox`** | Damage Number UI | `Enabled`, `FadeTime` |

## 🛡️ Utility & Exploit Configuration
| Box Name | Purpose | Notes |
| :--- | :--- | :--- |
| **`AntiBox`** | Anti-Aim / Anti-Lock | Settings to prevent being targeted. |
| **`FakeBox`** | Fake Lag / Desync | Controls `api.set_fake` behavior. |
| **`SpawnBox`** | Respawn / Godmode | Spawn protection abuse settings. |
| **`CartBox`** | Vehicle/Cart Exploits | Speed, Fly, or "Cart Crash" logic. |
| **`GripBox`** | Tool Grips | Custom gun positioning (e.g., reaching). |
| **`VoidBox`** | General Void Logic | Safety checks for voiding. |

## 📝 Scripting Example
To enable Auto-Stomp programmatically:
```lua
if getgenv().StompBox then
    getgenv().StompBox.Enabled = true
    print("Auto-Stomp Enabled via Box System!")
end
```
