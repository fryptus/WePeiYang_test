import 'dart:convert' show json;
import 'package:http_parser/http_parser.dart';
import 'package:we_pei_yang_flutter/auth/network/auth_service.dart';
import 'package:we_pei_yang_flutter/commons/network/classes_service.dart';
import 'package:we_pei_yang_flutter/commons/network/wpy_dio.dart';
import 'package:we_pei_yang_flutter/commons/preferences/common_prefs.dart';
import 'package:we_pei_yang_flutter/commons/util/logger.dart';
import 'package:we_pei_yang_flutter/commons/util/toast_provider.dart';
import 'package:we_pei_yang_flutter/commons/util/type_util.dart';
import 'package:we_pei_yang_flutter/gpa/model/gpa_model.dart';
import 'package:we_pei_yang_flutter/schedule/model/course.dart';
import 'package:we_pei_yang_flutter/schedule/model/exam.dart';

class _ClassesBackendDio extends DioAbstract {}

class ClassesBackendService {
  static final _classesBackedDio = _ClassesBackendDio();

  /// 从twt后端获取办公网上的课表、考表、GPA数据
  static Future<Tuple3<List<Course>, List<Exam>, GPABean>?> getClasses() async {
    try {
      var res = await _classesBackedDio.post(
        'https://learning.twt.edu.cn/get_classes',
        data: FormData.fromMap({
          'username': CommonPreferences.tjuuname.value,
          'passwd': CommonPreferences.tjupasswd.value,
        }),
      );
      if (res.data['code'] != 200) {
        ToastProvider.error(res.data['data']);
        return null;
      }
      var courses = _parseCourses(res.data['data']['courses']);
      var exams = _parseExams(res.data['data']['exams']);
      var gpaBean = _parseGPABean(res.data['data']['gpa']);
      var customCourses = <Course>[];
      if (CommonPreferences.courseData.value != '') {
        customCourses = CourseTable.fromJson(
                json.decode(CommonPreferences.courseData.value))
            .customCourses;
      }
      CommonPreferences.courseData.value =
          json.encode(CourseTable(courses, customCourses));
      CommonPreferences.examData.value = json.encode(ExamTable(exams));
      CommonPreferences.gpaData.value = json.encode(gpaBean);
      // 刷新学期数据
      await AuthService.getSemesterInfo();
      return Tuple3(courses, exams, gpaBean);
    } on DioException catch (e, s) {
      Logger.reportError(e, s);
      return null;
    }
  }

  /// 图形验证码识别
  static Future<String> ocr() async {
    var resp = await ClassesService.spiderDio.get(
        'https://sso.tju.edu.cn/cas/code',
        options: Options(responseType: ResponseType.bytes));
    var form = FormData();
    form.files.add(MapEntry(
        'image',
        MultipartFile.fromBytes(resp.data,
            filename: '123.png', contentType: MediaType("image", "jpg"))));
    resp = await _classesBackedDio.post('https://learning.twt.edu.cn/ocr',
        data: form);
    return resp.data['data'];
  }

  static List<Course> _parseCourses(Map<String, dynamic> data) {
    var courses = <Course>[];

    (data['major'] as List).forEach((m) {
      m['type'] = 0;
      courses.add(Course.fromJson(m));
    });
    (data['minor'] as List).forEach((m) {
      m['type'] = 0;
      courses.add(Course.fromJson(m));
    });

    return courses;
  }

  static List<Exam> _parseExams(List<dynamic> exams) {
    return exams.map((e) => Exam.fromJson(e)).toList();
  }

  static GPABean _parseGPABean(Map<String, dynamic> data) {
    var total = Total.fromJson(data['total']);

    var semesterMap = Map<String, List<GPACourse>>();

    (data['courses'] as List).forEach((c) {
      var course = GPACourse.fromJson(c);
      semesterMap.update(
        course.semester,
        (list) => list..add(course),
        ifAbsent: () => [course],
      );
    });

    List<GPAStat> stats = [];
    semesterMap.forEach((semester, courses) {
      stats.add(_calculateStat(semester, courses));
    });

    return GPABean(total, stats);
  }

  /// 计算每学期的总加权/绩点/学分
  /// [semester] 格式为`2021-2022 1`
  static GPAStat _calculateStat(String semester, List<GPACourse> courses) {
    semester = semester.split('-').last; // `2022 1`
    semester = '${semester[5]}H${semester[2]}${semester[3]}'; // `1H22`
    var totalCredit = 0.0;
    var totalScore = 0.0;
    var totalGPA = 0.0;
    courses.forEach((course) {
      if (course.credit == 0 || course.score == 0)
        return; // score为零时代表 F P 等情况(不会有人真能考零分吧)
      totalCredit += course.credit;
      totalScore += course.credit * course.score;
      totalGPA += course.credit * course.gpa;
    });

    if (totalCredit == 0) {
      totalScore = 0;
      totalGPA = 0;
    } else {
      totalScore = double.parse((totalScore / totalCredit).toStringAsFixed(2));
      totalGPA = double.parse((totalGPA / totalCredit).toStringAsFixed(2));
    }

    return GPAStat(
        semester, totalScore, totalGPA, totalCredit, [...courses]); // 这里是个深拷贝
  }
}
