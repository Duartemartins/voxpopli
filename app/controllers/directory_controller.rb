class DirectoryController < ApplicationController
  def index
    @builders = base_scope

    # Filter by skill
    if params[:skill].present?
      @builders = @builders.with_skill(params[:skill])
    end

    # Filter by looking_for
    if params[:looking_for].present?
      @builders = @builders.looking_for_type(params[:looking_for])
    end

    # Search by username, display_name, tagline, or bio
    if params[:q].present?
      search_term = "%#{params[:q].downcase}%"
      @builders = @builders.where(
        "LOWER(username) LIKE :q OR LOWER(display_name) LIKE :q OR LOWER(tagline) LIKE :q OR LOWER(bio) LIKE :q",
        q: search_term
      )
    end

    # Sorting
    @builders = case params[:sort]
    when "newest"
      @builders.newest
    when "active"
      @builders.recently_active
    else
      @builders.recently_active
    end

    @builders = @builders.page(params[:page]).per(24)

    # Collect all unique skills for filter dropdown
    @all_skills = collect_all_skills

    # Collect all products from all confirmed users
    @products = collect_all_products

    respond_to do |format|
      format.html
      format.json { render json: @builders.map(&:to_json_ld) }
    end
  end

  def show
    @builder = User.find_by!(username: params[:username])

    # Redirect to the main user profile page
    redirect_to user_path(@builder.username), status: :moved_permanently
  end

  def sitemap
    @builders = User.where.not(confirmed_at: nil).select(:username, :updated_at)

    respond_to do |format|
      format.xml
    end
  end

  private

  def base_scope
    User.where.not(confirmed_at: nil)
  end

  def collect_all_skills
    skills_arrays = User.where.not(skills: [ nil, "", "[]" ]).pluck(:skills)
    skills_arrays.flat_map do |skills_json|
      begin
        JSON.parse(skills_json.is_a?(String) ? skills_json : skills_json.to_json)
      rescue JSON::ParserError
        []
      end
    end.uniq.sort
  end

  def collect_all_products
    users_with_products = User.where.not(confirmed_at: nil)
                              .where.not(launched_products: [ nil, "", "[]" ])

    products = []
    users_with_products.find_each do |user|
      user.launched_products_list.each do |product|
        products << {
          name: product["name"],
          url: product["url"],
          description: product["description"],
          mrr: product["mrr"],
          revenue_confirmed: product["revenue_confirmed"],
          user: user
        }
      end
    end

    # Sort by MRR (highest first), then by name
    products.sort_by { |p| [ -(p[:mrr].to_i), p[:name].to_s.downcase ] }
  end
end
