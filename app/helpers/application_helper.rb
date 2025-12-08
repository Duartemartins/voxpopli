module ApplicationHelper
  def avatar_for(user, size: :medium)
    sizes = {
      small: "w-8 h-8",
      medium: "w-12 h-12",
      large: "w-20 h-20"
    }
    size_class = sizes[size] || sizes[:medium]

    if user.avatar_url.present?
      image_tag user.avatar_url,
                alt: "#{user.display_name || user.username}'s avatar",
                class: "#{size_class} rounded-full object-cover"
    else
      content_tag :div,
                  user.username[0].upcase,
                  class: "#{size_class} rounded-full bg-[#003399] text-white flex items-center justify-center font-medium #{size == :large ? 'text-2xl' : 'text-sm'}"
    end
  end
end
