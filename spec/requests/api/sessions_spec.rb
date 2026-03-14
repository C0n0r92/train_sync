require 'rails_helper'

RSpec.describe 'API::Sessions', type: :request do
  let(:coach) { create(:user, :coach) }
  let(:athlete) { create(:user, :athlete) }
  let(:workout) { create(:workout, :published, coach: coach) }
  let(:qr_code) { create(:qr_code, workout: workout) }

  describe 'POST /api/sessions' do
    let(:device_token) { SecureRandom.hex(32) }

    context 'with valid QR and device token' do
      let(:params) do
        {
          qr_code_short_id: qr_code.short_id,
          athlete_id: athlete.id,
          device_token: device_token
        }
      end

      it 'creates QR scan' do
        expect {
          post '/api/sessions', params: params
        }.to change(QrScan, :count).by(1)
      end

      it 'creates workout session' do
        expect {
          post '/api/sessions', params: params
        }.to change(WorkoutSession, :count).by(1)
      end

      it 'registers device token' do
        expect {
          post '/api/sessions', params: params
        }.to change(DeviceToken, :count).by(1)
      end

      it 'returns session data with device token' do
        post '/api/sessions', params: params

        expect(response).to have_http_status(:created)
        expect(json_response['id']).to be_present
        expect(json_response['device_token']).to eq(device_token)
        expect(json_response['athlete_id']).to eq(athlete.id)
        expect(json_response['workout']).to be_present
      end

      it 'sets device token to expire in 90 days' do
        post '/api/sessions', params: params

        device_token_obj = DeviceToken.find_by(token: device_token)
        expect(device_token_obj.expires_at).to be_within(1.day).of(90.days.from_now)
      end
    end

    context 'with expired QR code' do
      let(:expired_qr) { create(:qr_code, :expired, workout: workout) }
      let(:params) do
        {
          qr_code_short_id: expired_qr.short_id,
          athlete_id: athlete.id,
          device_token: device_token
        }
      end

      it 'returns error' do
        post '/api/sessions', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include('expired')
      end

      it 'does not create session' do
        expect {
          post '/api/sessions', params: params
        }.not_to change(WorkoutSession, :count)
      end
    end

    context 'with invalid QR code' do
      let(:params) do
        {
          qr_code_short_id: 'invalid_id',
          athlete_id: athlete.id,
          device_token: device_token
        }
      end

      it 'returns not found' do
        post '/api/sessions', params: params

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'without device token' do
      let(:params) do
        {
          qr_code_short_id: qr_code.short_id,
          athlete_id: athlete.id
        }
      end

      it 'returns error' do
        post '/api/sessions', params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include('Device token')
      end
    end

    context 'multiple sessions per athlete' do
      let(:params) do
        {
          qr_code_short_id: qr_code.short_id,
          athlete_id: athlete.id,
          device_token: device_token
        }
      end

      before do
        post '/api/sessions', params: params
      end

      it 'allows multiple sessions' do
        expect {
          post '/api/sessions', params: params
        }.to change(WorkoutSession, :count).by(1)
      end
    end
  end

  describe 'GET /api/sessions/current' do
    let(:device_token_obj) { create(:device_token, user: athlete) }
    let(:session) { create(:workout_session, athlete: athlete) }

    context 'with valid device token' do
      before do
        session # Create the session
      end

      it 'returns queued workout' do
        get '/api/sessions/current', headers: device_token_headers(device_token_obj.token)

        expect(response).to have_http_status(:ok)
        expect(json_response['workout']).to be_present
      end
    end

    context 'with expired device token' do
      let(:expired_token) do
        create(:device_token, user: athlete, expires_at: 1.day.ago)
      end

      it 'returns unauthorized' do
        get '/api/sessions/current', headers: device_token_headers(expired_token.token)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid device token' do
      it 'returns unauthorized' do
        get '/api/sessions/current', headers: device_token_headers('invalid_token')

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with no queued session' do
      let(:new_athlete) { create(:user, :athlete) }
      let(:new_token) { create(:device_token, user: new_athlete) }

      it 'returns null workout' do
        get '/api/sessions/current', headers: device_token_headers(new_token.token)

        expect(response).to have_http_status(:ok)
        expect(json_response['workout']).to be_nil
      end
    end
  end

  describe 'POST /api/sessions/:id/results' do
    let(:device_token_obj) { create(:device_token, user: athlete) }
    let(:session) { create(:workout_session, athlete: athlete) }
    let(:block_results) do
      [
        { block_index: 0, duration_seconds: 1800, distance_km: 5 },
        { block_index: 1, duration_seconds: 120 }
      ]
    end

    context 'with valid results' do
      let(:params) do
        {
          block_results: block_results
        }
      end

      it 'creates workout result' do
        expect {
          post "/api/sessions/#{session.id}/results", params: params, headers: device_token_headers(device_token_obj.token)
        }.to change(WorkoutResult, :count).by(1)
      end

      it 'marks session as completed' do
        post "/api/sessions/#{session.id}/results", params: params, headers: device_token_headers(device_token_obj.token)

        session.reload
        expect(session.completed_at).not_to be_nil
      end

      it 'returns result data' do
        post "/api/sessions/#{session.id}/results", params: params, headers: device_token_headers(device_token_obj.token)

        expect(response).to have_http_status(:created)
        expect(json_response['result']['block_results']).to eq(block_results)
      end
    end

    context 'with expired device token' do
      let(:expired_token) { create(:device_token, user: athlete, expires_at: 1.day.ago) }
      let(:params) { { block_results: block_results } }

      it 'returns unauthorized' do
        post "/api/sessions/#{session.id}/results", params: params, headers: device_token_headers(expired_token.token)

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with invalid session' do
      let(:params) { { block_results: block_results } }

      it 'returns not found' do
        post '/api/sessions/999999/results', params: params, headers: device_token_headers(device_token_obj.token)

        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with missing block results' do
      let(:params) { {} }

      it 'returns error' do
        post "/api/sessions/#{session.id}/results", params: params, headers: device_token_headers(device_token_obj.token)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context 'with invalid block results format' do
      let(:params) do
        {
          block_results: 'not an array'
        }
      end

      it 'returns error' do
        post "/api/sessions/#{session.id}/results", params: params, headers: device_token_headers(device_token_obj.token)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json_response['error']).to include('Invalid block results')
      end
    end
  end

  # Helper methods
  def device_token_headers(token)
    { 'X-Device-Token' => token }
  end

  def json_response
    @json_response ||= JSON.parse(response.body)
  end
end
