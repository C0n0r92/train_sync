require 'rails_helper'

RSpec.describe 'API::Auth', type: :request do
  describe 'POST /api/auth/signup' do
    context 'with valid coach signup' do
      let(:params) do
        {
          user: {
            email: 'coach@example.com',
            password: 'SecurePassword123!',
            password_confirmation: 'SecurePassword123!',
            role: 'coach'
          }
        }
      end

      it 'creates a new coach user' do
        expect {
          post '/api/auth/signup', params: params
        }.to change(User, :count).by(1)
      end

      it 'returns user data and token' do
        post '/api/auth/signup', params: params

        expect(response).to have_http_status(:created)
        expect(json_response['user']['email']).to eq('coach@example.com')
        expect(json_response['user']['role']).to eq('coach')
        expect(json_response['token']).to be_present
      end
    end

    context 'with valid athlete signup' do
      let(:params) do
        {
          user: {
            email: 'athlete@example.com',
            password: 'SecurePassword123!',
            password_confirmation: 'SecurePassword123!',
            role: 'athlete'
          }
        }
      end

      it 'creates a new athlete user' do
        expect {
          post '/api/auth/signup', params: params
        }.to change(User, :count).by(1)
      end

      it 'returns athlete user data' do
        post '/api/auth/signup', params: params

        expect(response).to have_http_status(:created)
        expect(json_response['user']['role']).to eq('athlete')
      end
    end

    context 'with missing email' do
      let(:params) do
        {
          user: {
            password: 'SecurePassword123!',
            password_confirmation: 'SecurePassword123!',
            role: 'coach'
          }
        }
      end

      it 'returns validation error' do
        post '/api/auth/signup', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to be_present
      end
    end

    context 'with password mismatch' do
      let(:params) do
        {
          user: {
            email: 'coach@example.com',
            password: 'SecurePassword123!',
            password_confirmation: 'DifferentPassword123!',
            role: 'coach'
          }
        }
      end

      it 'returns validation error' do
        post '/api/auth/signup', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include("doesn't match")
      end
    end

    context 'with duplicate email' do
      before do
        create(:user, email: 'existing@example.com')
      end

      let(:params) do
        {
          user: {
            email: 'existing@example.com',
            password: 'SecurePassword123!',
            password_confirmation: 'SecurePassword123!',
            role: 'coach'
          }
        }
      end

      it 'returns uniqueness error' do
        post '/api/auth/signup', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include('has already been taken')
      end
    end
  end

  describe 'POST /api/auth/login' do
    let(:user) { create(:user, email: 'user@example.com', password: 'SecurePassword123!') }

    context 'with valid credentials' do
      let(:params) do
        {
          email: 'user@example.com',
          password: 'SecurePassword123!'
        }
      end

      it 'returns user data and token' do
        user # Ensure user is created
        post '/api/auth/login', params: params

        expect(response).to have_http_status(:ok)
        expect(json_response['user']['email']).to eq('user@example.com')
        expect(json_response['token']).to be_present
      end
    end

    context 'with invalid email' do
      let(:params) do
        {
          email: 'nonexistent@example.com',
          password: 'SecurePassword123!'
        }
      end

      it 'returns unauthorized' do
        post '/api/auth/login', params: params

        expect(response).to have_http_status(:unauthorized)
        expect(json_response['error']).to include('Invalid')
      end
    end

    context 'with wrong password' do
      let(:params) do
        {
          email: 'user@example.com',
          password: 'WrongPassword123!'
        }
      end

      it 'returns unauthorized' do
        post '/api/auth/login', params: params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  def json_response
    @json_response ||= JSON.parse(response.body)
  rescue JSON::ParserError
    {}
  end
end
