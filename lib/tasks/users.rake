namespace :users do
  desc "Create an admin user. Usage: rails users:create ADMIN_RNC=... ADMIN_USER=... ADMIN_PASSWORD=... ADMIN_EMAIL=... "
  task create: :environment do
    rnc = ENV.fetch("ADMIN_RNC")
    username = ENV.fetch("ADMIN_USER")
    password = ENV.fetch("ADMIN_PASSWORD")
    email = ENV.fetch("ADMIN_EMAIL", "#{username}@sim.local")
    name = ENV.fetch("ADMIN_NAME", username)

    role = Role.find_or_create_by!(name: "admin") do |r|
      r.description = "Administrador del portal"
    end

    user = User.find_or_create_by!(rnc: rnc, username: username) do |u|
      u.name = name
      u.email = email
      u.role = role
      u.active = true
      u.password = password
    end

    puts "Usuario creado/actualizado: #{user.username} (RNC: #{user.rnc}, rol: #{user.role.name})"
  end
end
