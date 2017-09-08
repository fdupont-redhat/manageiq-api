RSpec.describe 'Authentications API' do
  let(:provider) { FactoryGirl.create(:provider_ansible_tower) }
  let(:auth) { FactoryGirl.create(:ansible_cloud_credential, :resource => provider) }
  let(:auth_2) { FactoryGirl.create(:ansible_cloud_credential, :resource => provider) }

  describe 'GET/api/authentications' do
    it 'lists all the authentication configuration script bases with an appropriate role' do
      auth = FactoryGirl.create(:authentication)
      api_basic_authorize collection_action_identifier(:authentications, :read, :get)

      run_get(api_authentications_url)

      expected = {
        'count'     => 1,
        'subcount'  => 1,
        'name'      => 'authentications',
        'resources' => [hash_including('href' => api_authentication_url(nil, auth.compressed_id))]
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to authentication configuration script bases without an appropriate role' do
      api_basic_authorize

      run_get(api_authentications_url)

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'GET /api/authentications/:id' do
    it 'will show an authentication configuration script base' do
      api_basic_authorize action_identifier(:authentications, :read, :resource_actions, :get)

      run_get(api_authentication_url(nil, auth))

      expected = {
        'href' => api_authentication_url(nil, auth.compressed_id)
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'forbids access to an authentication configuration script base' do
      api_basic_authorize

      run_get(api_authentication_url(nil, auth))

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'POST /api/authentications' do
    let(:manager) { provider.managers.first }
    let(:params) do
      {
        :id          => auth.id,
        :description => 'Description',
        :name        => 'Updated Credential'
      }
    end

    it 'will delete an authentication' do
      api_basic_authorize collection_action_identifier(:authentications, :delete, :post)

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Deleting Authentication'),
            'task_id' => a_kind_of(String)
          )
        ]
      }
      run_post(api_authentications_url, :action => 'delete', :resources => [{ 'id' => auth.id }])

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'verifies that the type is supported' do
      api_basic_authorize collection_action_identifier(:authentications, :delete, :post)
      auth = FactoryGirl.create(:authentication)

      run_post(api_authentications_url, :action => 'delete', :resources => [{ 'id' => auth.id }])

      expected = {
        'results' => [
          {
            'success' => false,
            'message' => "Delete not supported for Authentication id:#{auth.id} name: '#{auth.name}'"
          }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will delete multiple authentications' do
      api_basic_authorize collection_action_identifier(:authentications, :delete, :post)

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Deleting Authentication'),
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Deleting Authentication'),
            'task_id' => a_kind_of(String)
          )
        ]
      }
      run_post(api_authentications_url, :action => 'delete', :resources => [{ 'id' => auth.id }, { 'id' => auth_2.id }])

      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'will forbid deletion to an authentication without appropriate role' do
      auth = FactoryGirl.create(:authentication)
      api_basic_authorize

      run_post(api_authentications_url, :action => 'delete', :resources => [{ 'id' => auth.id }])
      expect(response).to have_http_status(:forbidden)
    end

    it 'can update an authentication with an appropriate role' do
      api_basic_authorize collection_action_identifier(:authentications, :edit)

      run_post(api_authentications_url, :action => 'edit', :resources => [params])

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Updating Authentication'),
            'task_id' => a_kind_of(String)
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can update an authentication with an appropriate role' do
      params2 = params.dup.merge(:id => auth_2.id)
      api_basic_authorize collection_action_identifier(:authentications, :edit)

      run_post(api_authentications_url, :action => 'edit', :resources => [params, params2])

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Updating Authentication'),
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => true,
            'message' => a_string_including('Updating Authentication'),
            'task_id' => a_kind_of(String)
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will forbid update to an authentication without appropriate role' do
      api_basic_authorize

      run_post(api_authentications_url, :action => 'edit', :resources => [params])

      expect(response).to have_http_status(:forbidden)
    end

    let(:create_params) do
      {
        :action           => 'create',
        :description      => "Description",
        :name             => "A Credential",
        :related          => {},
        :type             => 'ManageIQ::Providers::AnsibleTower::AutomationManager::Credential',
        :manager_resource => { :href => api_provider_url(nil, manager) }
      }
    end

    it 'requires a manager resource when creating an authentication' do
      api_basic_authorize collection_action_identifier(:authentications, :create, :post)

      run_post(api_authentications_url, :action => 'create', :type => 'Authentication')

      expected = {
        'results' => [
          { 'success' => false, 'message' => 'must supply a manager resource' }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires that the type support create_in_provider_queue' do
      api_basic_authorize collection_action_identifier(:authentications, :create, :post)

      run_post(api_authentications_url, :action => 'create', :type => 'Authentication', :manager_resource => { :href => api_provider_url(nil, manager) })

      expected = {
        'results' => [
          { 'success' => false, 'message' => 'type not currently supported' }
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can create an authentication' do
      api_basic_authorize collection_action_identifier(:authentications, :create, :post)

      expected = {
        'results' => [a_hash_including(
          'success' => true,
          'message' => 'Creating Authentication',
          'task_id' => a_kind_of(String)
        )]
      }
      run_post(api_authentications_url, create_params)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'can create authentications in bulk' do
      api_basic_authorize collection_action_identifier(:authentications, :create, :post)

      expected = {
        'results' => [
          a_hash_including(
            'success' => true,
            'message' => 'Creating Authentication',
            'task_id' => a_kind_of(String)
          ),
          a_hash_including(
            'success' => true,
            'message' => 'Creating Authentication',
            'task_id' => a_kind_of(String)
          )
        ]
      }
      run_post(api_authentications_url, :resources => [create_params, create_params])

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires a valid manager_resource' do
      api_basic_authorize collection_action_identifier(:authentications, :create, :post)
      create_params[:manager_resource] = { :href => '1' }

      expected = {
        'results' => [
          a_hash_including(
            'success' => false,
            'message' => 'invalid manger_resource href specified',
          )
        ]
      }
      run_post(api_authentications_url, :resources => [create_params])

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will forbid creation of an authentication without appropriate role' do
      api_basic_authorize

      run_post(api_authentications_url, :action => 'create')

      expect(response).to have_http_status(:forbidden)
    end

    it 'can refresh multiple authentications with an appropriate role' do
      api_basic_authorize collection_action_identifier(:authentications, :refresh, :post)

      run_post(api_authentications_url, :action => :refresh, :resources => [{ :id => auth.id}, {:id => auth_2.id}])

      expected = {
        'results' => [
          a_hash_including(
            'success'   => true,
            'message'   => a_string_including("Refreshing Authentication id:#{auth.id}"),
            'task_id'   => a_kind_of(String),
            'task_href' => /task/,
            'tasks'     => [a_hash_including('id' => a_kind_of(String), 'href' => /task/)]
          ),
          a_hash_including(
            'success'   => true,
            'message'   => a_string_including("Refreshing Authentication id:#{auth_2.id}"),
            'task_id'   => a_kind_of(String),
            'task_href' => /task/,
            'tasks'     => [a_hash_including('id' => a_kind_of(String), 'href' => /task/)]
          )
        ]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'PUT /api/authentications/:id' do
    let(:params) do
      {
        :description => 'Description',
        :name        => 'Updated Credential'
      }
    end

    it 'can update an authentication with an appropriate role' do
      api_basic_authorize collection_action_identifier(:authentications, :edit)

      run_put(api_authentication_url(nil, auth), :resource => params)

      expected = {
        'success' => true,
        'message' => a_string_including('Updating Authentication'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'PATCH /api/authentications/:id' do
    let(:params) do
      {
        :action      => 'edit',
        :description => 'Description',
        :name        => 'Updated Credential'
      }
    end

    it 'can update an authentication with an appropriate role' do
      api_basic_authorize collection_action_identifier(:authentications, :edit)

      run_patch(api_authentication_url(nil, auth), [params])

      expected = {
        'success' => true,
        'message' => a_string_including('Updating Authentication'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'POST /api/authentications/:id' do
    let(:params) do
      {
        :description => 'Description',
        :name        => 'Updated Credential'
      }
    end

    it 'will delete an authentication' do
      api_basic_authorize action_identifier(:authentications, :delete, :resource_actions, :post)

      run_post(api_authentication_url(nil, auth), :action => 'delete')

      expected = {
        'success' => true,
        'message' => a_string_including('Deleting Authentication'),
        'task_id' => a_kind_of(String)
      }
      expect(response.parsed_body).to include(expected)
      expect(response).to have_http_status(:ok)
    end

    it 'will not delete an authentication without an appropriate role' do
      api_basic_authorize

      run_post(api_authentication_url(nil, auth), :action => 'delete')

      expect(response).to have_http_status(:forbidden)
    end

    it 'can update an authentication with an appropriate role' do
      api_basic_authorize collection_action_identifier(:authentications, :edit)

      run_post(api_authentication_url(nil, auth), :action => 'edit', :resource => params)

      expected = {
        'success' => true,
        'message' => a_string_including('Updating Authentication'),
        'task_id' => a_kind_of(String)
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'requires that the type support update_in_provider_queue' do
      api_basic_authorize collection_action_identifier(:authentications, :edit)
      auth = FactoryGirl.create(:authentication)

      run_post(api_authentication_url(nil, auth), :action => 'edit', :resource => params)

      expected = {
        'success' => false,
        'message' => "Update not supported for Authentication id:#{auth.id} name: '#{auth.name}'"
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end

    it 'will forbid update to an authentication without appropriate role' do
      api_basic_authorize

      run_post(api_authentication_url(nil, auth), :action => 'edit', :resource => params)

      expect(response).to have_http_status(:forbidden)
    end

    it 'forbids refresh without an appropriate role' do
      api_basic_authorize

      run_post(api_authentication_url(nil, auth), :action => :refresh)

      expect(response).to have_http_status(:forbidden)
    end

    it 'can refresh a authentications with an appropriate role' do
      api_basic_authorize action_identifier(:authentications, :refresh)

      run_post(api_authentication_url(nil, auth), :action => :refresh)

      expected = {
        'success'   => true,
        'message'   => /Refreshing Authentication/,
        'task_id'   => a_kind_of(String),
        'task_href' => /task/,
        'tasks'     => [a_hash_including('id' => a_kind_of(String), 'href' => /tasks/)]
      }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(expected)
    end
  end

  describe 'DELETE /api/authentications/:id' do
    it 'will delete an authentication' do
      auth = FactoryGirl.create(:authentication)
      api_basic_authorize action_identifier(:authentications, :delete, :resource_actions, :delete)

      run_delete(api_authentication_url(nil, auth))

      expect(response).to have_http_status(:no_content)
    end

    it 'will not delete an authentication without an appropriate role' do
      auth = FactoryGirl.create(:authentication)
      api_basic_authorize

      run_delete(api_authentication_url(nil, auth))

      expect(response).to have_http_status(:forbidden)
    end

    it 'will raise an error if the authentication does not exist' do
      api_basic_authorize action_identifier(:authentications, :delete, :resource_actions, :delete)

      run_delete(api_authentication_url(nil, 999_999))

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'OPTIONS /api/authentications' do
    it 'returns expected and additional attributes' do
      run_options(api_authentications_url)

      additional_options = {
        'credential_types' => build_credential_options
      }
      expect_options_results(:authentications, additional_options)
    end
  end

  def build_credential_options
    Authentication::CREDENTIAL_TYPES.each_with_object({}) do |(description, klass), hash|
      hash[description] = klass.constantize.descendants.each_with_object({}) do |subklass, fields|
        next unless defined? subklass::API_OPTIONS
        subklass::API_OPTIONS.tap do |options|
          options[:attributes].each do |_k, val|
            val[:type] = val[:type].to_s if val[:type]
          end
          fields[subklass.name] = options
        end
      end
    end.deep_stringify_keys
  end
end