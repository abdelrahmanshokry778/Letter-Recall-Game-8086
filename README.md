# Letter-Recall-Game-8086
A word/letter recall game built in x86 Assembly for EMU8086 emulator and MTS-86C Kit — Microprocessors project

> A memory challenge game written in **x86 Assembly Language**, built and tested on the **EMU8086 emulator**.  
> University of Alexandria — Faculty of Engineering  
> Division of Communications & Electronics  
> **Subject:** Microprocessors & Interfacing — Spring 2026  
> **Lecturer:** Dr. Nayera Sadek

---

## 📖 About the Project

**Letter Recall Game** is a memory-based game where the player must memorize a sequence of randomly generated uppercase letters and then type them back correctly — all in Assembly language.

The game runs entirely in a DOS-style console through the EMU8086 emulator, using BIOS and DOS interrupts for I/O, timing, and screen control.

---

## 🎮 How to Play

1. Launch the program in EMU8086.
2. Select a **difficulty level** when prompted.
3. A sequence of letters will appear on screen — memorize them!
4. After the timer expires, the screen clears.
5. Type back the exact sequence you saw.
6. Pass all 3 levels to **WIN** 🏆

---

## 🏗️ Game Structure

| Level | Letters to Memorize |
|-------|-------------------|
| Level 1 | 3 random letters |
| Level 2 | 5 random letters |
| Level 3 | 7 random letters |

If you answer **wrong**, you'll see the correct sequence and be given a **retry option (Y/N)**.  
Choosing **N** ends the game.

---

## ⚙️ Difficulty Modes

Chosen by the player at the start of each game:

| Key | Mode   | Letters Visible For |
|-----|--------|---------------------|
| `E` | Easy   | ~5 seconds          |
| `M` | Medium | ~3 seconds          |
| `H` | Hard   | ~1.5 seconds        |

Both uppercase and lowercase inputs are accepted.

---

## 🎲 Random Letter Generation

Letters are **truly random** on every run using a **Linear Congruential Generator (LCG)** seeded by the BIOS timer (`INT 1AH`):

```
seed = BIOS_ticks XOR previous_seed
AL   = (109 × AL + 11) XOR timer_low
letter = (AL mod 26) + 'A'
```

This ensures a different sequence every time you play.

---

## 🛠️ Technical Details

| Property       | Value                              |
|----------------|------------------------------------|
| Platform       | EMU8086 Emulator                   |
| Assembler      | EMU8086 built-in / MASM compatible |
| Memory Model   | `.MODEL SMALL`                     |
| Stack Size     | `200H`                             |
| Delay Factor   | `01H` (tuned for EMU8086 speed)    |

### Key Interrupts Used

| Interrupt | Purpose                         |
|-----------|---------------------------------|
| `INT 21H / AH=09H` | Print string to console  |
| `INT 21H / AH=08H` | Read key (no echo)        |
| `INT 21H / AH=02H` | Print single character    |
| `INT 21H / AH=4CH` | Exit program              |
| `INT 10H / AH=06H` | Clear screen (BIOS)       |
| `INT 10H / AH=02H` | Set cursor position       |
| `INT 1AH / AH=00H` | Read BIOS timer ticks (RNG seed) |

---

## 🚀 How to Run

### Requirements
- [EMU8086](http://www.emu8086.com/) installed on your machine (Windows)

### Steps
1. Open **EMU8086**.
2. Click **File → Open** and select `Emulator.asm`.
3. Click **Compile** (F5).
4. Click **Run** ▶️.
5. Interact with the game in the **Virtual Screen** window.

> ✅ No external libraries or additional tools needed.

---

## 📁 File Structure

```
/
├── Emulator.asm      ← Main game source code (this version)
├── KIT.ASM           ← Hardware version for MTS-86C Kit
└── README.md         ← This file
```

---
