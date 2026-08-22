import app from "ags/gtk4/app"
import style from "./style.scss"
import ControlCenter, { refreshAllPolls } from "./widget/ControlCenter"

app.start({
  css: style,
  requestHandler(request, res) {
    if (request === "toggle control-center") {
        app.toggle_window("control-center")
        refreshAllPolls()
    }
    res("")
  },
  main() {
    app.get_monitors().map(ControlCenter)
  },
})
