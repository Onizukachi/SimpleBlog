require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

#Инициализируем глобальную переменную, и создается бд, если ее не было
def init_rb
	@db = SQLite3::Database.new 'leprosorium.db'
	@db.results_as_hash = true
end

#before вызывается каждый раз при перезагрузке страницы
before do
	#Инициализация бд
	init_rb
end

#configure вызывается каждый раз при конфигурации приложения, изменении кода и перезагрузки страницы
configure do
	init_rb
	@db.execute 'CREATE TABLE IF NOT EXISTS Post 
	(
		"id" INTEGER PRIMARY KEY AUTOINCREMENT, "created_date" DATE, "content" TEXT
	)'
end

get '/' do
	#Выбираем список постов из бд
	@results = @db.execute 'select * from Post order by id desc'
	erb :index
end

#Обработчик get запроса /new 
#Браузер получает страницу с сервера
get '/new' do
	erb :new
end

#Обработчик post запроса /new
#браузер отпарвляет данные на сервер
#erb просто без : загружает каркас страницы с layout
post '/new' do
	content = params[:content]

	#валидация параметра
	if content.length <= 0
		@error = 'Type post text'
		return erb :new
	end
	
	#Вместо ? подставится значение из массива потом и сохраняем в бд
	@db.execute 'insert into Post (content, created_date) values (?, datetime())', [content]
	
	#перенаправление на главную страницу
	redirect to '/'
  end

  #Вывод информации о посте
  #Универсальный обработчик для всех постов, преобразует все что после / в нашу переменную, и дальше делаем что хотим
  get '/details/:post_id' do
	post_id = params[:post_id]

	results = @db.execute 'select * from Post where id = ?', [post_id]
	#Выбираем только одну строчку
	@row = results[0]

	erb :details
  end