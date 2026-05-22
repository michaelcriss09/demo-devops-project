from django.test import TestCase
from api.models import User
from api.serializers import UserSerializer


class UserSerializerTest(TestCase):
    def setUp(self):
        self.valid_data = {'name': 'Jane Doe', 'dni': '9876543210123'}
        self.user = User.objects.create(name='John Doe', dni='1234567890123')

    def test_serializer_with_valid_data(self):
        serializer = UserSerializer(data=self.valid_data)
        self.assertTrue(serializer.is_valid())

    def test_serializer_missing_name(self):
        serializer = UserSerializer(data={'dni': '9876543210123'})
        self.assertFalse(serializer.is_valid())
        self.assertIn('name', serializer.errors)

    def test_serializer_missing_dni(self):
        serializer = UserSerializer(data={'name': 'Jane Doe'})
        self.assertFalse(serializer.is_valid())
        self.assertIn('dni', serializer.errors)

    def test_serializer_contains_expected_fields(self):
        serializer = UserSerializer(self.user)
        self.assertSetEqual(set(serializer.data.keys()), {'id', 'name', 'dni'})

    def test_serializer_data_matches_model(self):
        serializer = UserSerializer(self.user)
        self.assertEqual(serializer.data['name'], self.user.name)
        self.assertEqual(serializer.data['dni'], self.user.dni)

    def test_serializer_dni_exceeds_max_length(self):
        serializer = UserSerializer(data={'name': 'Jane', 'dni': 'X' * 14})
        self.assertFalse(serializer.is_valid())
        self.assertIn('dni', serializer.errors)

    def test_serializer_name_exceeds_max_length(self):
        serializer = UserSerializer(data={'name': 'A' * 31, 'dni': '1234567890123'})
        self.assertFalse(serializer.is_valid())
        self.assertIn('name', serializer.errors)

    def test_serializer_save_creates_user(self):
        serializer = UserSerializer(data=self.valid_data)
        self.assertTrue(serializer.is_valid())
        user = serializer.save()
        self.assertEqual(User.objects.count(), 2)
        self.assertEqual(user.name, self.valid_data['name'])
