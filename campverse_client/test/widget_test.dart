import 'package:campverse/core/models/app_role.dart';
import 'package:campverse/core/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppRole Model & Claim Security Tests', () {
    test('AppRole parses all valid PostgreSQL database strings', () {
      expect(AppRole.fromDbString('super_admin'), AppRole.superAdmin);
      expect(AppRole.fromDbString('principal'), AppRole.principal);
      expect(AppRole.fromDbString('office_admin'), AppRole.officeAdmin);
      expect(AppRole.fromDbString('student_union'), AppRole.studentUnion);
      expect(AppRole.fromDbString('hod'), AppRole.hod);
      expect(AppRole.fromDbString('faculty'), AppRole.faculty);
      expect(AppRole.fromDbString('club_admin'), AppRole.clubAdmin);
      expect(AppRole.fromDbString('student'), AppRole.student);
    });

    test('AppRole returns default student for unknown or null strings', () {
      expect(AppRole.fromDbString(null), AppRole.student);
      expect(AppRole.fromDbString('invalid_role'), AppRole.student);
    });

    test('AppRole.fromClaim safely parses JWT claim strings', () {
      expect(AppRole.fromClaim('club_admin'), AppRole.clubAdmin);
      expect(AppRole.fromClaim('hod'), AppRole.hod);
      expect(AppRole.fromClaim(null), isNull);
      expect(AppRole.fromClaim(''), isNull);
    });

    test('HOD role correctly implies faculty access', () {
      expect(AppRole.hod.impliesFaculty, isTrue);
      expect(AppRole.student.impliesFaculty, isFalse);
      expect(AppRole.clubAdmin.impliesFaculty, isFalse);
    });

    test('AuthUserState computed properties', () {
      const state1 = AuthUserState(
        availableRoles: [AppRole.student, AppRole.clubAdmin],
      );
      expect(state1.hasMultipleRoles, isTrue);

      const state2 = AuthUserState();
      expect(state2.hasMultipleRoles, isFalse);
    });
  });
}
