require 'rails_helper'

RSpec.describe 'API::Workouts', type: :request do
  let(:coach) { create(:user, :coach) }
  let(:athlete) { create(:user, :athlete) }
  let(:auth_token) { generate_jwt_token(coach) }

  describe 'POST /api/workouts' do
    context 'as authenticated coach' do
      let(:params) do
        {
          workout: {
            name: 'Morning Run',
            blocks: [{ type: 'run', distance: 5 }],
            is_public: false
          }
        }
      end

      it 'creates a new workout' do
        expect {
          post '/api/workouts', params: params, headers: auth_headers(auth_token)
        }.to change(Workout, :count).by(1)
      end

      it 'sets correct attributes' do
        post '/api/workouts', params: params, headers: auth_headers(auth_token)

        expect(response).to have_http_status(:created)
        expect(json_response['name']).to eq('Morning Run')
        expect(json_response['status']).to eq('draft')
        expect(json_response['version']).to eq(1)
        expect(json_response['coach_id']).to eq(coach.id)
      end

      context 'with empty blocks (draft)' do
        let(:params) do
          {
            workout: {
              name: 'Empty Workout',
              blocks: [],
              is_public: false
            }
          }
        end

        it 'allows creation with empty blocks' do
          post '/api/workouts', params: params, headers: auth_headers(auth_token)

          expect(response).to have_http_status(:created)
          expect(json_response['blocks']).to eq([])
        end
      end
    end

    context 'as athlete' do
      let(:athlete_token) { generate_jwt_token(athlete) }
      let(:params) do
        {
          workout: {
            name: 'Athlete Workout',
            blocks: [],
            is_public: false
          }
        }
      end

      it 'returns forbidden' do
        post '/api/workouts', params: params, headers: auth_headers(athlete_token)

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'without authentication' do
      let(:params) do
        {
          workout: {
            name: 'No Auth Workout',
            blocks: [],
            is_public: false
          }
        }
      end

      it 'returns unauthorized' do
        post '/api/workouts', params: params

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'PATCH /api/workouts/:id' do
    let(:workout) { create(:workout, coach: coach) }

    context 'as owner coach' do
      it 'updates draft workout' do
        patch "/api/workouts/#{workout.id}", params: {
          workout: { name: 'Updated Name' }
        }, headers: auth_headers(auth_token)

        expect(response).to have_http_status(:ok)
        expect(json_response['name']).to eq('Updated Name')
        expect(json_response['version']).to eq(2)
      end

      it 'increments version on update' do
        initial_version = workout.version

        patch "/api/workouts/#{workout.id}", params: {
          workout: { blocks: [{ type: 'run' }] }
        }, headers: auth_headers(auth_token)

        expect(json_response['version']).to eq(initial_version + 1)
      end
    end

    context 'when trying to update published workout' do
      let(:workout) { create(:workout, :published, coach: coach) }

      it 'returns error' do
        patch "/api/workouts/#{workout.id}", params: {
          workout: { name: 'Updated' }
        }, headers: auth_headers(auth_token)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include('Cannot update published')
      end
    end

    context 'as non-owner coach' do
      let(:other_coach) { create(:user, :coach) }
      let(:other_token) { generate_jwt_token(other_coach) }

      it 'returns forbidden' do
        patch "/api/workouts/#{workout.id}", params: {
          workout: { name: 'Hacked' }
        }, headers: auth_headers(other_token)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/workouts/:id/publish' do
    context 'with valid draft workout' do
      let(:workout) { create(:workout, coach: coach, blocks: [{ type: 'run' }]) }

      it 'publishes the workout' do
        post "/api/workouts/#{workout.id}/publish", headers: auth_headers(auth_token)

        expect(response).to have_http_status(:ok)
        expect(json_response['status']).to eq('published')
      end
    end

    context 'with empty blocks' do
      let(:workout) { create(:workout, coach: coach, blocks: []) }

      it 'returns error' do
        post "/api/workouts/#{workout.id}/publish", headers: auth_headers(auth_token)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include('empty')
      end
    end

    context 'already published workout' do
      let(:workout) { create(:workout, :published, coach: coach) }

      it 'returns error' do
        post "/api/workouts/#{workout.id}/publish", headers: auth_headers(auth_token)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include('Already published')
      end
    end

    context 'after publishing, workout cannot be edited' do
      let(:workout) { create(:workout, coach: coach, blocks: [{ type: 'run' }]) }

      before do
        post "/api/workouts/#{workout.id}/publish", headers: auth_headers(auth_token)
      end

      it 'update returns error' do
        patch "/api/workouts/#{workout.id}", params: {
          workout: { name: 'New Name' }
        }, headers: auth_headers(auth_token)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'GET /api/workouts/:id' do
    context 'coach fetching own workout' do
      let(:workout) { create(:workout, coach: coach) }

      it 'returns workout data' do
        get "/api/workouts/#{workout.id}", headers: auth_headers(auth_token)

        expect(response).to have_http_status(:ok)
        expect(json_response['id']).to eq(workout.id)
      end
    end

    context 'athlete fetching published workout' do
      let(:workout) { create(:workout, :published, coach: coach) }
      let(:athlete_token) { generate_jwt_token(athlete) }

      it 'returns workout data' do
        get "/api/workouts/#{workout.id}", headers: auth_headers(athlete_token)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'athlete fetching draft workout (not owner)' do
      let(:workout) { create(:workout, coach: coach) }
      let(:athlete_token) { generate_jwt_token(athlete) }

      it 'returns forbidden' do
        get "/api/workouts/#{workout.id}", headers: auth_headers(athlete_token)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'POST /api/workouts/:id/qr' do
    context 'with published workout' do
      let(:workout) { create(:workout, :published, coach: coach) }
      let(:params) do
        {
          qr_code: {
            variant: 'public'
          }
        }
      end

      it 'generates QR code' do
        expect {
          post "/api/workouts/#{workout.id}/qr", params: params, headers: auth_headers(auth_token)
        }.to change(QrCode, :count).by(1)
      end

      it 'returns QR data with short_id' do
        post "/api/workouts/#{workout.id}/qr", params: params, headers: auth_headers(auth_token)

        expect(response).to have_http_status(:created)
        expect(json_response['short_id']).to be_present
        expect(json_response['url']).to include('/qr/')
      end
    end

    context 'with draft workout' do
      let(:workout) { create(:workout, coach: coach) }
      let(:params) { { qr_code: { variant: 'public' } } }

      it 'returns error' do
        post "/api/workouts/#{workout.id}/qr", params: params, headers: auth_headers(auth_token)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include('publish')
      end
    end

    context 'by non-owner' do
      let(:workout) { create(:workout, :published, coach: coach) }
      let(:other_coach) { create(:user, :coach) }
      let(:other_token) { generate_jwt_token(other_coach) }
      let(:params) { { qr_code: { variant: 'public' } } }

      it 'returns forbidden' do
        post "/api/workouts/#{workout.id}/qr", params: params, headers: auth_headers(other_token)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  # Helper methods
  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      email: user.email,
      role: user.role,
      iat: Time.current.to_i,
      exp: (Time.current + 24.hours).to_i
    }
    JWT.encode(payload, Rails.application.config.secret_key_base, 'HS256')
  end

  def auth_headers(token)
    { 'Authorization' => "Bearer #{token}" }
  end

  def json_response
    @json_response ||= JSON.parse(response.body)
  end
end
