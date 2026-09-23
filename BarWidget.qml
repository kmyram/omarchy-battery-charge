import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  id: root

  property QtObject bar: null
  property string moduleName: ""
  property var settings: null

  property string limit: ""
  property bool available: false
  property bool helperMissing: false
  property bool popupOpen: false
  property int refreshTries: 0

  readonly property string helper: "/usr/local/bin/battery-charge-limit"
  readonly property var choices: [
    { value: "60", label: "60%", hint: "Maximum lifespan" },
    { value: "80", label: "80%", hint: "Balanced" },
    { value: "100", label: "100%", hint: "Full charge" }
  ]

  function close() { popupOpen = false }

  function refresh() {
    if (!reader.running) reader.running = true
  }

  function apply(value) {
    if (value !== "60" && value !== "80" && value !== "100") return
    if (!bar) return
    limit = value
    popupOpen = false
    bar.run(helper + " set " + value)
    refreshTries = 8
  }

  function tooltip() {
    if (helperMissing) return "Charge limit needs a one-time setup. Run install.sh from the plugin folder."
    if (!available || limit === "") return "Charge limit"
    return "Charge limit " + limit + "%. Click to choose 60, 80, or 100."
  }

  visible: available || helperMissing
  implicitWidth: Math.max(label.implicitWidth + Style.space(12), bar && bar.vertical ? bar.barSize : 0)
  implicitHeight: bar ? bar.barSize : Style.space(26)

  Component.onCompleted: refresh()

  Process {
    id: reader
    command: [root.helper, "get"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var value = String(text || "").trim()
        root.available = value === "60" || value === "80" || value === "100" || /^[0-9]+$/.test(value)
        if (root.available) {
          root.helperMissing = false
          root.limit = value
        }
      }
    }
    onExited: function(code) {
      root.helperMissing = code === 127
      if (code !== 0) root.available = false
    }
  }

  Timer {
    interval: 500
    repeat: true
    running: root.refreshTries > 0
    onTriggered: {
      root.refreshTries -= 1
      root.refresh()
    }
  }

  Timer {
    interval: 30000
    repeat: true
    running: true
    triggeredOnStart: false
    onTriggered: root.refresh()
  }

  Text {
    id: label
    anchors.centerIn: parent
    text: root.helperMissing ? "limit" : (root.limit === "" ? "—" : (root.bar && root.bar.vertical ? root.limit : root.limit + "%"))
    color: root.bar ? root.bar.foreground : "white"
    font.family: root.bar ? root.bar.fontFamily : "monospace"
    font.pixelSize: Style.font.bodySmall
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: root.popupOpen = !root.popupOpen
    onWheel: function(wheel) {
      var order = ["60", "80", "100"]
      var index = order.indexOf(root.limit)
      if (index < 0) index = 0
      var next = wheel.angleDelta.y > 0 ? (index + 1) % order.length : (index + order.length - 1) % order.length
      root.apply(order[next])
    }
    onEntered: if (root.bar) root.bar.showTooltip(root, root.tooltip())
    onExited: if (root.bar) root.bar.hideTooltip(root)
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    contentWidth: popup.fittedContentWidth(Style.space(220))
    contentHeight: popup.fittedContentHeight(menu.implicitHeight)

    Column {
      id: menu
      width: parent.width
      spacing: Style.space(4)

      Text {
        width: parent.width
        text: "Charge limit"
        color: root.bar ? root.bar.foreground : "white"
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }

      Text {
        width: parent.width
        wrapMode: Text.WordWrap
        text: "60, 80, or 100% on laptops whose kernel can limit charging."
        color: root.bar ? Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.7) : "white"
        font.family: root.bar ? root.bar.fontFamily : "monospace"
        font.pixelSize: Style.font.caption
      }

      Repeater {
        model: root.choices

        Rectangle {
          required property var modelData
          width: menu.width
          height: Style.space(36)
          radius: Style.space(6)
          color: root.bar && modelData.value === root.limit
                ? Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.16)
                : "transparent"

          Row {
            anchors.fill: parent
            anchors.leftMargin: Style.space(8)
            anchors.rightMargin: Style.space(8)
            spacing: Style.space(8)

            Text {
              anchors.verticalCenter: parent.verticalCenter
              width: Style.space(48)
              text: modelData.label
              color: root.bar ? root.bar.foreground : "white"
              font.family: root.bar ? root.bar.fontFamily : "monospace"
              font.pixelSize: Style.font.bodySmall
              font.bold: modelData.value === root.limit
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.hint
              color: root.bar ? Qt.rgba(root.bar.foreground.r, root.bar.foreground.g, root.bar.foreground.b, 0.7) : "white"
              font.family: root.bar ? root.bar.fontFamily : "monospace"
              font.pixelSize: Style.font.bodySmall
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: root.apply(modelData.value)
          }
        }
      }
    }
  }
}
