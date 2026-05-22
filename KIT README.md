# 🔧 Letter Recall Game — MTS-86C Hardware Kit Version

> A memory challenge game written in **bare-metal x86 Assembly Language**, running directly on the **MTS-86C Lab Kit** with a real LCD display and physical keypad.  
> University of Alexandria — Faculty of Engineering  
> Division of Communications & Electronics  
> **Subject:** Microprocessors & Interfacing — Spring 2026  
> **Lecturer:** Dr. Nayera Sadek

---

## 📖 About the Project

**Letter Recall Game** is a memory-based game where the player must memorize a sequence of letters displayed on the kit's **16×2 LCD screen**, then enter them back using the **hex keypad**.

Unlike the emulator version, this code runs on **real hardware** with no operating system — all I/O is handled by direct port-mapped communication with the LCD controller and keypad scanner. No DOS, no BIOS — pure bare-metal Assembly.

---

## 🎮 How to Play

1. Power on the MTS-86C kit and load the program.
2. The LCD displays **"LETTER RECALL"** — press any key to start.
3. A sequence of characters will appear on the LCD — memorize them!
4. After a delay, the screen clears and prompts you to type the sequence.
5. Enter each character using the hex keypad.
6. Pass all 3 levels to **WIN** 🏆

---

## 🏗️ Game Structure

| Level | Characters to Memorize |
|-------|------------------------|
| Level 1 | 3 characters (`A`, `3`, `F`) |
| Level 2 | 5 characters (`B`, `7`, `1`, `C`, `9`) |
| Level 3 | 7 characters (`E`, `0`, `D`, `5`, `2`, `8`, `4`) |

If you answer **wrong**, the LCD shows the correct sequence and asks:  
`Retry?(1=Y 0=N)` — Press `1` to retry or `0` to end the game.

---

## ⌨️ Keypad Input

The MTS-86C keypad uses **hex scan codes** (0–F). The program translates them to displayable characters using a lookup table:

```
Scan Code:  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F
Character: '0''1''2''3''4''5''6''7''8''9''A''B''C''D''E''F'
```

---

## 🛠️ Technical Details

| Property       | Value                           |
|----------------|---------------------------------|
| Platform       | MTS-86C Lab Kit (bare-metal)    |
| Memory Model   | `.MODEL TINY`                   |
| Origin         | `ORG 0000H`                     |
| Delay Factor   | `08H` (tuned for ~10 MHz kit)   |

### Hardware Port Addresses

| Constant        | Address   | Purpose                 |
|-----------------|-----------|-------------------------|
| `LCD_CMD_PORT`  | `0FFC1H`  | Send command to LCD     |
| `LCD_STAT_PORT` | `0FFC3H`  | Read LCD busy flag      |
| `LCD_DATA_PORT` | `0FFC5H`  | Send character to LCD   |
| `KBD_CMD_PORT`  | `0FFEAH`  | Read keypad status      |
| `KBD_DATA_PORT` | `0FFE8H`  | Read keypad scan code   |

### Key Subroutines

| Subroutine   | Description                                          |
|--------------|------------------------------------------------------|
| `LCD_INIT`   | Initializes LCD (8-bit mode, display on, clear)      |
| `LCD_CLEAR`  | Sends clear-display command (`01H`)                  |
| `LCD_LINE2`  | Moves cursor to start of second LCD line (`C0H`)     |
| `LCD_PRINT`  | Prints a `$`-terminated string from `[SI]`           |
| `WRITE_CMD`  | Sends a command byte to LCD (waits for busy flag)    |
| `WRITE_DATA` | Sends a data byte to LCD (waits for busy flag)       |
| `WAIT_KEY`   | Polls keypad until a key is pressed, returns ASCII   |
| `DELAY_LONG` | Busy-wait delay loop calibrated for kit speed        |
| `DO_LEVEL`   | Runs one full level: show → hide → input → check     |

---

## 🚀 How to Load onto the Kit

### Requirements
- MTS-86C Lab Kit
- Assembler that produces a flat binary (e.g., MASM with `TINY` model, or compatible)
- Lab kit loader/programmer software (provided in your lab environment)

### Steps
1. Assemble `KIT.ASM` to produce a raw binary (`.COM` format or equivalent for the kit).
2. Use the kit's loader software to transfer the binary to the kit's memory starting at `0000H`.
3. Reset/run the kit — the program starts at `START` and jumps to `MAIN`.
4. Follow the LCD prompts and use the hex keypad to play.

> ⚠️ **Important:** Do not run this file in EMU8086 — it uses direct hardware port I/O and will not work correctly in the emulator. Use `Emulator.asm` for EMU8086.

---

## 📁 File Structure

```
/
├── KIT.ASM           ← Hardware source code (this version)
├── Emulator.asm      ← Emulator version for EMU8086
└── README_KIT.md     ← This file
```

---

## ⚖️ Differences from the Emulator Version

| Feature              | Emulator Version         | Kit Version (This File)      |
|----------------------|--------------------------|------------------------------|
| Output               | DOS console (80×25 text) | 16×2 LCD display             |
| Input                | PC keyboard              | Hex keypad (0–F)             |
| Screen clear         | `INT 10H` BIOS call      | `LCD_CLEAR` command (`01H`)  |
| Random generation    | BIOS timer + LCG         | Fixed predefined sequences   |
| Difficulty selection | E / M / H at runtime     | Fixed delay (hardware-tuned) |
| OS dependency        | DOS/BIOS interrupts       | None — pure bare-metal       |
| Memory model         | `.MODEL SMALL`           | `.MODEL TINY` (`ORG 0000H`)  |
| Delay factor         | `01H`                    | `08H`                        |

---
## 📝 Notes

- The LCD busy flag (`bit 7` of `LCD_STAT_PORT`) is checked before every command/data write to avoid overflowing the LCD controller.
- The keypad returns a 4-bit scan code (0x0–0xF); the `XLAT` instruction translates it via `SCAN_TABLE` to its ASCII character.
- The program halts with `HLT` after win or game over.
- Sequences in this version are **hardcoded** (not random) to ensure reliability on hardware without a guaranteed timer source.
