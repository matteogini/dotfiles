import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { execAsync } from "ags/process"
import { createPoll } from "ags/time"
import { createState } from "gnim"

// Polling bindings using ags/time
const vol = createPoll(0, 2000, ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], (out) => {
    const match = out.match(/Volume:\s+([\d.]+)/)
    return match ? parseFloat(match[1]) : 0
})

const mic = createPoll(0, 2000, ["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"], (out) => {
    const match = out.match(/Volume:\s+([\d.]+)/)
    return match ? parseFloat(match[1]) : 0
})

const bright = createPoll(0, 2000, ["brightnessctl", "-m"], (out) => {
    const parts = out.split(",")
    return parts.length > 3 ? parseInt(parts[3]) / 100 : 0
})

const kbd = createPoll(0, 2000, ["asusctl", "leds", "get"], (out) => {
    const s = out.toLowerCase();
    if (s.includes("high")) return 1;
    if (s.includes("med")) return 0.66;
    if (s.includes("low")) return 0.33;
    return 0;
})

const mediaTitle = createPoll("", 1000, ["bash", "-c", "playerctl metadata title || echo ''"], out => out.trim().substring(0, 35))
const mediaArtist = createPoll("", 1000, ["bash", "-c", "playerctl metadata artist || echo ''"], out => out.trim().substring(0, 35))
const mediaStatus = createPoll("", 1000, ["bash", "-c", "playerctl status || echo ''"], out => out.trim())

const batLimit = createPoll(0.8, 5000, ["bash", "-c", "awk -F'[:,]' '/charge_control_end_threshold/ {print int($2); exit}' /etc/asusd/asusd.ron || echo 80"], (out, prev) => {
    const val = parseInt(out)
    return isNaN(val) ? (prev ?? 0.8) : val / 100
})

const cpuWatt = createPoll(0.5, 5000, ["bash", "-c", "sudo ryzenadj -i 2>/dev/null | awk -F'|' '/STAPM LIMIT/ {print int($3)}'"], (out, prev) => {
    if (!out || out.trim() === "") return prev ?? 0.5;
    const val = parseInt(out)
    if (isNaN(val)) return prev ?? 0.5;
    return Math.max(0, Math.min(1, (val - 5) / 45)) // Map 5W-50W back to 0.0-1.0
})

const gpuMode = createPoll("Integrated", 5000, ["supergfxctl", "-g"], out => out.trim())

const wifiMode = createPoll("disabled", 3000, ["bash", "-c", "if [ \"$(nmcli radio wifi)\" = \"disabled\" ]; then echo 'disabled'; else ssid=$(nmcli -t -f type,name connection show --active | awk -F: '$1==\"802-11-wireless\"{print $2}' | head -n1); echo \"${ssid:-disconnected}\"; fi"], out => out.trim())

const btMode = createPoll("disabled", 3000, ["bash", "-c", "if rfkill list bluetooth | grep -q \"Soft blocked: yes\"; then echo \"disabled\"; else bt=$(bluetoothctl devices Connected | head -n1 | awk '{for(i=3;i<=NF;++i) printf \"%s \", $i; print \"\"}'); echo \"${bt:-disconnected}\"; fi"], out => out.trim())

const profileMode = createPoll("Balanced", 2000, ["bash", "-c", "asusctl profile get || echo 'Active profile: Balanced'"], out => {
    const match = out.match(/Active profile:\s+(.*)/)
    return match ? match[1].trim() : "Balanced"
})


function SliderRow({ label, stateVar, formatCommand, displayFormat, debounceMs = 0, lockMs = 3000 }: { label: string, stateVar: any, formatCommand: (val: number) => string, displayFormat: (val: number) => string, debounceMs?: number, lockMs?: number }) {
  const initialVal = stateVar?.peek ? stateVar.peek() : stateVar;
  const [displayVal, setDisplayVal] = createState(displayFormat(initialVal));
  const [sliderVal, setSliderVal] = createState(initialVal);

  let lastUserEdit = 0;

  if (stateVar?.subscribe) {
    stateVar.subscribe(() => {
      // Prevent the slider from snapping back while dragging or immediately after
      if (Date.now() - lastUserEdit > lockMs) {
        setSliderVal(stateVar.peek());
        setDisplayVal(displayFormat(stateVar.peek()));
      }
    })
  }

  let timer: any = null;

  return (
    <box cssClasses={["row"]} orientation={Gtk.Orientation.HORIZONTAL}>
      <label cssClasses={["label"]} label={label} widthRequest={85} xalign={0} />
      <slider
        hexpand
        drawValue={false}
        value={sliderVal}
        onValueChanged={(self) => {
          lastUserEdit = Date.now();
          setDisplayVal(displayFormat(self.value))
          const cmd = formatCommand(self.value)
          
          if (debounceMs > 0) {
              if (timer) clearTimeout(timer);
              timer = setTimeout(() => {
                  execAsync(["bash", "-c", cmd]).catch(console.error)
              }, debounceMs)
          } else {
              execAsync(["bash", "-c", cmd]).catch(console.error)
          }
        }}
      />
      <label 
        cssClasses={["label"]} 
        widthRequest={45} 
        xalign={1}
        label={displayVal}
      />
    </box>
  )
}

function GPUSelector() {
  const switchGPU = () => {
    execAsync(["bash", "-c", "current=$(supergfxctl -g); if [ \"$current\" = \"Integrated\" ]; then fish -c switch-hybrid; else fish -c switch-integrated; fi"]).catch(console.error)
  }

  return (
    <box cssClasses={["row"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={5}>
      <label cssClasses={["label"]} label="GPU" widthRequest={85} xalign={0} />
      <button hexpand onClicked={switchGPU}>
        <box halign={Gtk.Align.CENTER} spacing={5}>
            <label label={gpuMode} />
            <label label=" (Click to Switch)" />
        </box>
      </button>
    </box>
  )
}

function ToggleRow() {
    const openWifi = () => {
        app.toggle_window("control-center")
        execAsync(["bash", "-c", "~/.config/tofi/tofi-wifi.sh"]).catch(console.error)
    }

    const openBt = () => {
        app.toggle_window("control-center")
        execAsync(["bash", "-c", "~/.config/tofi/tofi-bluetooth.sh"]).catch(console.error)
    }

    return (
        <box cssClasses={["row"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={10}>
            <button hexpand onClicked={openWifi} cssClasses={["toggle-button"]}>
                <box halign={Gtk.Align.CENTER} spacing={5}>
                    <label label={wifiMode.as(v => {
                        if (v === "disabled") return "Wi-Fi Off";
                        if (v === "disconnected") return "Wi-Fi On";
                        return v;
                    })} />
                </box>
            </button>
            <button hexpand onClicked={openBt} cssClasses={["toggle-button"]}>
                <box halign={Gtk.Align.CENTER} spacing={5}>
                    <label label={btMode.as(v => {
                        if (v === "disabled") return "BT Off";
                        if (v === "disconnected") return "BT On";
                        return v;
                    })} />
                </box>
            </button>
        </box>
    )
}

let currentColorHex = "ff0000";

function ColorRow() {
    const setColor = (hex: string) => {
        currentColorHex = hex;
        execAsync(["asusctl", "aura", "effect", "static", "-c", hex]).catch(console.error)
    }

    return (
      <box cssClasses={["row"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={5}>
        <label cssClasses={["label"]} label="Kbd Color" widthRequest={85} xalign={0} />
        <button hexpand onClicked={() => setColor("ff0000")}><label label="Red" /></button>
        <button hexpand onClicked={() => setColor("00ff00")}><label label="Green" /></button>
        <button hexpand onClicked={() => setColor("0000ff")}><label label="Blue" /></button>
        <button hexpand onClicked={() => setColor("ffffff")}><label label="White" /></button>
        <button hexpand onClicked={() => setColor("ff00ff")}><label label="Purple" /></button>
      </box>
    )
}

function PowerProfiles() {
    const setProfile = (p: string) => execAsync(["asusctl", "profile", "set", p]).catch(console.error)
    return (
        <box cssClasses={["row"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={5}>
            <label cssClasses={["label"]} label="Profile" widthRequest={85} xalign={0} />
            <button hexpand onClicked={() => setProfile("Quiet")}>
                <label label={profileMode.as(v => v === "Quiet" ? "✓ Quiet" : "Quiet")} />
            </button>
            <button hexpand onClicked={() => setProfile("Balanced")}>
                <label label={profileMode.as(v => v === "Balanced" ? "✓ Balanced" : "Balanced")} />
            </button>
            <button hexpand onClicked={() => setProfile("Performance")}>
                <label label={profileMode.as(v => v === "Performance" ? "✓ Perf" : "Perf")} />
            </button>
        </box>
    )
}

const AURA_EFFECTS = ["static", "breathe", "pulse"];

function AuraEffects() {
    const setEffect = (eff: string) => {
        let args = ["asusctl", "aura", "effect", eff];
        const c1 = currentColorHex; // Inherits the last selected color from ColorRow!
        const c2 = "0000ff"; // Default Blue for breathe
        const spd = "med";

        if (eff === "static") args.push("-c", c1);
        else if (eff === "breathe") args.push("--colour", c1, "--colour2", c2, "--speed", spd);
        else if (eff === "pulse") args.push("-c", c1);

        execAsync(args).catch(console.error);
    }
    
    return (
        <box cssClasses={["row"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={5}>
            <label cssClasses={["label"]} label="Aura FX" widthRequest={85} xalign={0} />
            {AURA_EFFECTS.map(eff => (
                <button hexpand onClicked={() => setEffect(eff)}>
                    <label label={eff} />
                </button>
            ))}
        </box>
    )
}

function SlashLighting() {
    const openSlashMenu = () => {
        app.toggle_window("control-center");
        execAsync(["bash", "-c", "~/.config/tofi/tofi-slash.sh"]).catch(console.error);
    }

    return (
        <box cssClasses={["row"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={5}>
            <label cssClasses={["label"]} label="Slash" widthRequest={85} xalign={0} />
            <button hexpand onClicked={() => execAsync(["asusctl", "slash", "--enable"]).catch(console.error)}>
                <label label="On" />
            </button>
            <button hexpand onClicked={() => execAsync(["asusctl", "slash", "--disable"]).catch(console.error)}>
                <label label="Off" />
            </button>
            <button hexpand onClicked={openSlashMenu}>
                <label label="Animation" />
            </button>
        </box>
    )
}

function MediaPlayer() {
    return (
        <box cssClasses={["section"]} orientation={Gtk.Orientation.VERTICAL} spacing={5} visible={mediaStatus.as(s => s !== "")}>
            <label cssClasses={["label"]} label={mediaTitle.as(t => t || "Unknown Title")} xalign={0.5} />
            <label cssClasses={["value"]} label={mediaArtist.as(a => a || "Unknown Artist")} xalign={0.5} />
            
            <box cssClasses={["row"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={10} halign={Gtk.Align.CENTER}>
                <button onClicked={() => execAsync(["playerctl", "previous"]).catch(console.error)}>
                    <label label="<" />
                </button>
                <button onClicked={() => execAsync(["playerctl", "play-pause"]).catch(console.error)}>
                    <label label="-" />
                </button>
                <button onClicked={() => execAsync(["playerctl", "next"]).catch(console.error)}>
                    <label label=">" />
                </button>
            </box>
        </box>
    )
}

function ControlCenterContent() {
    const [activeTab, setActiveTab] = createState(0);

    return (
        <box orientation={Gtk.Orientation.VERTICAL} spacing={10}>
            {/* Tab Bar */}
            <box cssClasses={["tab-bar"]} orientation={Gtk.Orientation.HORIZONTAL} spacing={5}>
                <button hexpand cssClasses={activeTab.as(v => v === 0 ? ["tab", "active"] : ["tab"])} onClicked={() => setActiveTab(0)}>
                    <label label="Quick" />
                </button>
                <button hexpand cssClasses={activeTab.as(v => v === 1 ? ["tab", "active"] : ["tab"])} onClicked={() => setActiveTab(1)}>
                    <label label="Light" />
                </button>
                <button hexpand cssClasses={activeTab.as(v => v === 2 ? ["tab", "active"] : ["tab"])} onClicked={() => setActiveTab(2)}>
                    <label label="Advanced" />
                </button>
            </box>

            {/* Tab Content */}
            <box cssClasses={["tab-content"]} orientation={Gtk.Orientation.VERTICAL}>
                <box orientation={Gtk.Orientation.VERTICAL} spacing={10} visible={activeTab.as(v => v === 0)}>
                    <MediaPlayer />
                    <ToggleRow />
                    <label label="SYSTEM" xalign={0} cssClasses={["label"]} />
                    <SliderRow label="Volume" stateVar={vol} displayFormat={(v) => `${Math.round(v * 100)}%`} formatCommand={(v) => `wpctl set-volume @DEFAULT_AUDIO_SINK@ ${v.toFixed(2)}`} />
                    <SliderRow label="Mic" stateVar={mic} displayFormat={(v) => `${Math.round(v * 100)}%`} formatCommand={(v) => `wpctl set-volume @DEFAULT_AUDIO_SOURCE@ ${v.toFixed(2)}`} />
                    <SliderRow label="Brightness" stateVar={bright} displayFormat={(v) => `${Math.max(1, Math.round(v * 100))}%`} formatCommand={(v) => `brightnessctl s ${Math.max(1, Math.round(v * 100))}%`} />
                </box>

                <box orientation={Gtk.Orientation.VERTICAL} spacing={10} visible={activeTab.as(v => v === 1)}>
                    <label label="LIGHTING" xalign={0} cssClasses={["label"]} />
                    <SliderRow label="Kbd Lght" stateVar={kbd} displayFormat={(v) => { const lvl = Math.round(v * 3); if (lvl === 0) return "Off"; if (lvl === 1) return "Low"; if (lvl === 2) return "Med"; return "High"; }} formatCommand={(v) => { let lvl = "off"; if (v > 0.1) lvl = "low"; if (v > 0.5) lvl = "med"; if (v > 0.8) lvl = "high"; return `asusctl leds set ${lvl}`; }} debounceMs={200} />
                    <ColorRow />
                    <AuraEffects />
                    <SlashLighting />
                </box>

                <box orientation={Gtk.Orientation.VERTICAL} spacing={10} visible={activeTab.as(v => v === 2)}>
                    <label label="PERFORMANCE" xalign={0} cssClasses={["label"]} />
                    <PowerProfiles />
                    <SliderRow label="CPU Watt" stateVar={cpuWatt} displayFormat={(v) => `${Math.round(v * 45 + 5)}W`} formatCommand={(v) => `setwatt ${Math.round(v * 45 + 5)}`} debounceMs={500} lockMs={6000} />
                    <SliderRow label="Bat Limit" stateVar={batLimit} displayFormat={(v) => `${Math.max(20, Math.round(v * 100))}%`} formatCommand={(v) => `asusctl battery limit ${Math.max(20, Math.round(v * 100))}`} debounceMs={500} />
                    <GPUSelector />
                </box>
            </box>
        </box>
    )
}

export default function ControlCenter(gdkmonitor: Gdk.Monitor) {
  const { TOP, RIGHT } = Astal.WindowAnchor

  return (
    <window
      visible={false} 
      name="control-center"
      cssClasses={["ControlCenter"]}
      anchor={TOP | RIGHT}
      application={app}
      gdkmonitor={gdkmonitor}
      marginTop={10}
      marginRight={10}
    >
      <ControlCenterContent />
    </window>
  )
}
