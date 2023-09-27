//
//  MidView.swift
//  PeiYangLiteWidgetExtension
//
//  Created by 游奕桁 on 2020/9/17.
//

import SwiftUI
import WidgetKit

struct MediumView: View {
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var store = SwiftStorage.courseTable
    private var courseTable: CourseTable { store.object }
    
    let entry: DataEntry
    let theme: WColorTheme
    
    /// 是否为简写
    var isPlaceHolder: Bool { entry.isPlaceHolder }
    
    /// 星期简写 比如Thu
    var weekday: String {
        return courseTable.currentDate.format(with: "E")
    }
    
    @State var courses: [WCourse] = []
    
    private var colorProperty: ColorProperty {
        ColorProperty(wTheme: theme, colorTheme: colorScheme)
    }
    
    private func ClassLine(course: WCourse) -> some View {
        return HStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.wColor(.main, colorProperty))
                .frame(width: 4, height: 28)
            VStack(alignment: .leading) {
                HStack(alignment: .center, spacing: 2) {
                    Text(course.course.name)
                        .wfont(.pingfang, size: 11)
                        .foregroundColor(.wColor(.title, colorProperty))
                        .lineLimit(1)
                    Group {
                        if course.isDup {
                            Image("warn")
                                .resizable()
                                .frame(width: 12, height: 12)
                        } else {
                            EmptyView()
                        }
                    }
                }
                
                // 自动缩小防止显示不全
                HStack(spacing: 0) {
                    Text("\(course.arrange.location) ")
                        .foregroundColor(.wColor(.body, colorProperty))
                        .wfont(.sfpro, size: 11)
                    
                    Text("\(course.arrange.unitTimeString)")
                        .foregroundColor(.wColor(.body, colorProperty))
                        .wfont(.sfpro, size: 11)
                        .fixedSize(horizontal: true, vertical: false)
                }
            }
        }
    }
    
    private func TomorrowLogo() -> some View {
        Text("明天")
            .wfont(.pingfang, size: 10)
            .foregroundColor(.wColor(.main, colorProperty))
            .padding(.top, -5)
            .padding(.bottom, -5)
    }
    
    private func MoreCourses(cnt: Int) -> some View {
        Text("今天还有 \(cnt) 个课程")
            .wfont(.pingfang, size: 10)
            .foregroundColor(.wColor(.body, colorProperty))
            .padding(.top, -6)

    }
    
    private func DetailView() -> some View {
        let data: [(WCourse, AnyView)] = courses.prefix(2).map{ ($0, AnyView(ClassLine(course: $0))) }
        var cnt = 0
        
        // 判断是否有“今天还有更多课”
        if courses.count > 2 {
            for i in 0..<courses.count {
                if courses[i].arrange.weekday == courseTable.currentDay {
                    cnt +=  1
                }
            }
        }
        
        return VStack(alignment: .leading) {
            if(!data[0].0.isToday){
                TomorrowLogo()  //在第一个课前加入“明天”
            }
            ForEach(0..<data.count, id: \.self) { i in
                if (!data[i].0.isToday && data[0].0.isToday){
                    TomorrowLogo()  //在第一节为今天，第二节课为明天的时候加入“明天”
                }
                data[i].1
            }
            if(courses.count > 2 && data[0].0.isToday && data[1].0.isToday){
                MoreCourses(cnt: cnt)   //在接下来连续两节课为今天的时候插入“今天还有x节课”
            }
        }
    }
    
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text("\(weekday).")
                        .foregroundColor(.wColor(.main, colorProperty))
                        .wfont(.product, size: 36)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Image(theme == .white ? "peiyanglogo-white" : "peiyanglogo-blue")
                        .resizable()
                        .frame(width: 21, height: 10)
                        .padding(.top, 10)
                        .scaledToFit()
                }
                .padding(.bottom, -8) //-1和0简直就是天壤之别。。。

                Spacer()
                VStack{
                    if courses.isEmpty {
                        Text("这两天都没有课程啦，\n假期愉快！")
                            .wfont(.pingfang, size: 10)
                            .foregroundColor(.wColor(.title, colorProperty))
                    } else {
                        DetailView()
                    }
                }
                Spacer()

                
            }
            .frame(minWidth: 144, maxWidth: 144, minHeight: 0, maxHeight: .infinity, alignment: .top)  //使VStack占据父视图所有高度
            .onAppear {
                store.reloadData()
                courses = WidgetCourseManager.getCourses(courseTable: courseTable)
            }
            Spacer()
            
            ZStack{
                RoundedRectangle(cornerSize: CGSize(width: 12, height: 12))
                    .foregroundColor(.white)
                    .opacity(0.94)
                    .frame(width: 150, height: 134)
            }
        }
        .padding(12)
        .background(theme == .blue ?
                    AnyView(LinearGradient(colors: [
                        .hex("#3586E2"),
                        .hex("#3F8FE3"),
                        .hex("#519FE4"),
                        .hex("#70BAE7"),
                    ], startPoint: .topLeading, endPoint: .bottomTrailing))
                    : AnyView(Color.white))
    }
}

