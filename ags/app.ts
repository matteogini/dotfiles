import app from "ags/gtk4/app"
import style from "./style.scss"
import ControlCenter from "./widget/ControlCenter"

app.start({
  css: style,
  requestHandler(request, res) {
    if (request === "toggle control-center") {
        app.toggle_window("control-center")
    }
    res("")
  },
  main() {
    app.get_monitors().map(ControlCenter)
  },
})
