import json
from django.urls import reverse
from rest_framework.test import APITestCase
from api.models import User


class UserListViewTest(APITestCase):
    def setUp(self):
        self.url = reverse('users-list')
        User.objects.create(name='John Doe', dni='1234567890123')

    def test_list_returns_200(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)

    def test_list_returns_all_users(self):
        User.objects.create(name='Jane Doe', dni='9876543210123')
        response = self.client.get(self.url)
        self.assertEqual(len(response.json()), 2)

    def test_list_returns_correct_fields(self):
        response = self.client.get(self.url)
        user_data = response.json()[0]
        self.assertIn('id', user_data)
        self.assertIn('name', user_data)
        self.assertIn('dni', user_data)

    def test_list_empty_when_no_users(self):
        User.objects.all().delete()
        response = self.client.get(self.url)
        self.assertEqual(response.json(), [])


class UserCreateViewTest(APITestCase):
    def setUp(self):
        self.url = reverse('users-list')
        self.valid_payload = {'name': 'Jane Doe', 'dni': '9876543210123'}
        User.objects.create(name='John Doe', dni='1234567890123')

    def test_create_user_returns_201(self):
        response = self.client.post(self.url, self.valid_payload, format='json')
        self.assertEqual(response.status_code, 201)

    def test_create_user_persists_in_db(self):
        self.client.post(self.url, self.valid_payload, format='json')
        self.assertEqual(User.objects.count(), 2)

    def test_create_user_returns_correct_data(self):
        response = self.client.post(self.url, self.valid_payload, format='json')
        body = response.json()
        self.assertEqual(body['name'], self.valid_payload['name'])
        self.assertEqual(body['dni'], self.valid_payload['dni'])
        self.assertIn('id', body)

    def test_create_user_duplicate_dni_returns_400(self):
        response = self.client.post(self.url, {'name': 'Other', 'dni': '1234567890123'}, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()['detail'], 'User already exists')

    def test_create_user_missing_name_returns_400(self):
        response = self.client.post(self.url, {'dni': '5555555555555'}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_create_user_missing_dni_returns_400(self):
        response = self.client.post(self.url, {'name': 'No DNI'}, format='json')
        self.assertEqual(response.status_code, 400)

    def test_create_user_empty_payload_returns_400(self):
        response = self.client.post(self.url, {}, format='json')
        self.assertEqual(response.status_code, 400)


class UserDetailViewTest(APITestCase):
    def setUp(self):
        self.user = User.objects.create(name='John Doe', dni='1234567890123')
        self.url = reverse('users-detail', kwargs={'pk': self.user.pk})

    def test_retrieve_user_returns_200(self):
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)

    def test_retrieve_user_returns_correct_data(self):
        response = self.client.get(self.url)
        body = response.json()
        self.assertEqual(body['id'], self.user.pk)
        self.assertEqual(body['name'], self.user.name)
        self.assertEqual(body['dni'], self.user.dni)

    def test_retrieve_nonexistent_user_returns_404(self):
        url = reverse('users-detail', kwargs={'pk': 9999})
        response = self.client.get(url)
        self.assertEqual(response.status_code, 404)
