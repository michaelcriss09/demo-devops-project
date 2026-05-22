from django.test import TestCase
from api.models import User


class UserModelTest(TestCase):
    def setUp(self):
        self.user = User.objects.create(name='John Doe', dni='1234567890123')

    def test_str_returns_name(self):
        self.assertEqual(str(self.user), 'John Doe')

    def test_dni_is_unique(self):
        with self.assertRaises(Exception):
            User.objects.create(name='Another', dni='1234567890123')

    def test_name_max_length(self):
        field = User._meta.get_field('name')
        self.assertEqual(field.max_length, 30)

    def test_dni_max_length(self):
        field = User._meta.get_field('dni')
        self.assertEqual(field.max_length, 13)

    def test_create_user(self):
        self.assertEqual(User.objects.count(), 1)
        self.assertEqual(self.user.name, 'John Doe')
        self.assertEqual(self.user.dni, '1234567890123')
