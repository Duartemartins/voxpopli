module AvatarHelper
  def user_avatar(user, classes: "w-10 h-10")
    if user.avatar.attached?
      image_tag user.avatar, class: "#{classes} object-cover border border-steel bg-carbon"
    else
      # Minidenticons implementation
      # Extract size from classes (w-10 = 2.5rem = 40px, w-24 = 6rem = 96px, etc.)
      size_map = {
        "w-5" => "20",
        "w-8" => "32",
        "w-10" => "40",
        "w-16" => "64",
        "w-20" => "80",
        "w-24" => "96"
      }

      size = size_map[classes.split.find { |c| size_map.key?(c) }] || "40"

      # Use Acid Lime color for the identicon
      content_tag "minidenticon-svg", "",
        username: user.username,
        saturation: "95",
        lightness: "55",
        width: size,
        height: size,
        class: "#{classes} border border-steel bg-carbon block",
        style: "color: #CCFF00;"
    end
  end
end
