json.extract! project, :id, :title, :github_repo_url, :created_at, :updated_at
json.url project_url(project, format: :json)
