//
//  MenubarItem.swift
//  keyrace-mac
//
//  Created by Nat Friedman on 1/3/21.
//

import Foundation
import Cocoa
import SwiftUI
import Charts

class ChartValueFormatter: NSObject, IValueFormatter {

    func stringForValue(_ value: Double, entry: ChartDataEntry, dataSetIndex: Int, viewPortHandler: ViewPortHandler?) -> String {
        if value == 0.0 {
            return ""
        }

        return String(Int(value))
    }
}

public class MinAxisValueFormatter: NSObject, IAxisValueFormatter {
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date()
        let calendar = Calendar.current
        let min = calendar.component(.minute, from: date)
        
        var m = min - 20 + Int(value)
        if m < 0 {
            m += 60
        }
        
        return String(format: ":%02d", m)
    }
}

public class HourAxisValueFormatter: NSObject, IAxisValueFormatter {
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        if (value == 12.0) {
            return "noon"
        }

        var str = "\(Int(value)%12)"
        
        if (value < 12.0) {
            str += "am"
        } else {
            str += "pm"
        }
        
        return str
    }
}

public class KeyAxisValueFormatter: NSObject, IAxisValueFormatter {
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return "\(Character(UnicodeScalar(Int(97 + value))!))"
    }
}

class TypingChart: BarChartView {
    
    func NewData(_ typingCount: [Int], color: [Int] = [255, 255, 0]) {
        
        let yse1 = typingCount.enumerated().map { x, y in return BarChartDataEntry(x: Double(x), y: Double(y)) }

        let data = BarChartData()
        let ds1 = BarChartDataSet(entries: yse1, label: "Hello")
        ds1.colors = [NSUIColor.init(srgbRed: CGFloat(color[0])/255.0, green: CGFloat(color[1])/255.0, blue: CGFloat(color[2])/255.0, alpha: 1.0)]
        data.addDataSet(ds1)
        data.barWidth = Double(0.5)

        data.setDrawValues(true)
        let valueFormatter = ChartValueFormatter()
        data.setValueFormatter(valueFormatter)

        self.data = data
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let xArray = Array(1..<24)
        let ys1 = xArray.map { x in return abs(sin(Double(x) / 2.0 / 3.141 * 1.5)) }
        
        let yse1 = ys1.enumerated().map { x, y in return BarChartDataEntry(x: Double(x), y: y) }

        let data = BarChartData()
        let ds1 = BarChartDataSet(entries: yse1, label: "Hello")
        ds1.colors = [NSUIColor.red]
        data.addDataSet(ds1)
        data.barWidth = Double(0.5)
        
        self.data = data
        
        self.legend.enabled = false
        self.leftAxis.drawGridLinesEnabled = false
        self.leftAxis.drawAxisLineEnabled = false
        self.leftAxis.drawLabelsEnabled = false
        self.rightAxis.drawGridLinesEnabled = false
        self.rightAxis.drawAxisLineEnabled = false
        self.rightAxis.drawLabelsEnabled = false
        self.xAxis.drawGridLinesEnabled = false
        self.xAxis.drawAxisLineEnabled = false
        self.xAxis.drawLabelsEnabled = false
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

class MenubarItem : NSObject {
    private var settingsMenuItem : NSMenuItem
    private var settingsSubMenu : NSMenu
    private var onlyShowFollows : NSMenuItem
    
    private var loginMenuItem : NSMenuItem
    private var quitMenuItem : NSMenuItem
    private var minChartItem : NSMenuItem
    private var hourChartItem : NSMenuItem
    private var keyChartItem : NSMenuItem
    private var leaderboardItem : NSMenuItem
    
    var gh : GitHub? {
        didSet {
            if gh!.loggedIn {
                loggedIn()
            }
        }
    }
    
    var keyTap : KeyTap?

    var statusBarItem : NSStatusItem = {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        return item
    }()

    let statusBarMenu = NSMenu(title: "foo")

    init(title: String) {
        settingsMenuItem = NSMenuItem(title: "Settings", action: nil, keyEquivalent: "")
        settingsSubMenu = NSMenu.init(title: "Settings")
        settingsMenuItem.submenu = settingsSubMenu
        onlyShowFollows = NSMenuItem(title: "Only show users I follow", action: #selector(onlyShowUsersIFollow), keyEquivalent: "")
        loginMenuItem = NSMenuItem(title: "Login with GitHub", action: #selector(login), keyEquivalent: "")
        
        quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "")
        minChartItem = NSMenuItem()
        hourChartItem = NSMenuItem()
        keyChartItem = NSMenuItem()
        leaderboardItem = NSMenuItem()

        super.init()

        statusBarItem.button?.title = title

        let minChart = TypingChart(frame: CGRect(x: 0, y: 0, width: 350, height: 100))
        minChartItem.view = minChart
        let hourChart = TypingChart(frame: CGRect(x: 0, y: 0, width: 350, height: 100))
        hourChartItem.view = hourChart
        let keyChart = TypingChart(frame: CGRect(x: 0, y: 0, width: 350, height: 100))
        keyChartItem.view = keyChart

        minChart.xAxis.labelPosition = .bottom
        minChart.xAxis.labelFont = .systemFont(ofSize: 8.0)
        minChart.xAxis.granularity = 3
        minChart.xAxis.valueFormatter = MinAxisValueFormatter()
        minChart.xAxis.drawLabelsEnabled = true

        hourChart.xAxis.labelPosition = .bottom
        hourChart.xAxis.labelFont = .systemFont(ofSize: 8.0)
        hourChart.xAxis.granularity = 3
        hourChart.xAxis.valueFormatter = HourAxisValueFormatter()
        hourChart.xAxis.drawLabelsEnabled = true

        keyChart.xAxis.labelPosition = .bottom
        keyChart.xAxis.labelFont = .systemFont(ofSize: 8.0)
        keyChart.xAxis.labelCount = 25
        keyChart.xAxis.granularity = 1
        keyChart.xAxis.valueFormatter = KeyAxisValueFormatter()
        keyChart.xAxis.drawLabelsEnabled = true
        

        let leaderboard = NSTextView(frame: CGRect(x: 0, y: 0, width: 350, height: 0))
        leaderboard.string = ""
        leaderboard.isRichText = true
        leaderboard.drawsBackground = false
        leaderboard.textContainerInset = NSSizeFromString("10")
        leaderboardItem.view = leaderboard
        
        quitMenuItem.target = self
        loginMenuItem.target = self
        
        settingsMenuItem.target = self
        onlyShowFollows.target = self
        settingsSubMenu.addItem(onlyShowFollows)
        settingsSubMenu.addItem(loginMenuItem)
        settingsSubMenu.addItem(quitMenuItem)

        statusBarMenu.addItem(minChartItem)
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(hourChartItem)
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(keyChartItem)
        statusBarMenu.addItem(NSMenuItem.separator())
        statusBarMenu.addItem(leaderboardItem)
        statusBarMenu.addItem(settingsMenuItem)
        statusBarItem.menu = statusBarMenu
        
        statusBarMenu.delegate = self
    }
    
    func loggedIn() {
        if gh?.username != nil {
            loginMenuItem.title = "Logged in as @" + gh!.username!
            loginMenuItem.isEnabled = false
            loginMenuItem.target = nil
        }
    }
    
    @objc func login() {
        if gh == nil {
            return
        }
        
        if gh!.token != nil {
            gh!.getUserName()
            loggedIn()
            return
        }

        let alert = NSAlert()
        alert.messageText = "Login with GitHub"

        DispatchQueue.global(qos: .background).async {
            let (userCode, verificationUri) = self.gh!.startDeviceAuth(clientId: "a945f87ad537bfddb109", scope: "", callback: self.loggedIn)
            
            if (userCode == "") {
                alert.informativeText = "Could not contact GitHub. Try again later."
                alert.addButton(withTitle: "Ok")
                alert.runModal()
                return
            }
            
            DispatchQueue.main.async {
                alert.informativeText = "Your GitHub device code is \(userCode)"
                alert.addButton(withTitle: "Copy device code and open browser")
                alert.addButton(withTitle: "Cancel")

                let modalResult = alert.runModal()
                switch modalResult {
                case .alertFirstButtonReturn:
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(userCode, forType: .string)
                    let url = URL(string: verificationUri)!
                    NSWorkspace.shared.open(url)
                default:
                    return
                }
            }
        }
    }
    
    @objc func onlyShowUsersIFollow() {
        // Toggle the state.
        if (self.onlyShowFollows.state == NSControl.StateValue.off) {
            // Set it to be on
            self.onlyShowFollows.state = NSControl.StateValue.on
        } else {
            self.onlyShowFollows.state = NSControl.StateValue.off
        }
    
        // Save the setting.
        MenuSettings.setOnlyShowFollows(self.onlyShowFollows.state)
        // Update the leaderboard.
        self.keyTap?.uploadCount()
    }

    @objc func quit() {
        print("quitting")
        exit(0)
    }
}

extension MenubarItem : NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        // Update the bar chart
        (self.minChartItem.view as? TypingChart)?.NewData((keyTap?.getMinutesChart())!)
        (self.hourChartItem.view as? TypingChart)?.NewData((keyTap?.getHoursChart())!, color: [255, 0, 0])
        (self.keyChartItem.view as? TypingChart)?.NewData((keyTap?.getKeysChart())!, color: [0, 255, 255])
        let leaderboardView = (self.leaderboardItem.view as? NSTextView)
        let str = (keyTap?.getLeaderboardText())
        leaderboardView!.performValidatedReplacement(
            in: NSRange(location: 0, length: leaderboardView!.string.count),
            with: str!)
        
        self.onlyShowFollows.state = MenuSettings.getOnlyShowFollows()
        
        self.leaderboardItem.isHidden = true // FIXME why doesn't this work?
    }
}
