FROM mcr.microsoft.com/dotnet/sdk:8.0 AS base

# Устанавливаем dotnet-script
RUN dotnet tool install -g dotnet-script
ENV PATH="$PATH:/root/.dotnet/tools"

# Создаём рабочую директорию
WORKDIR /app

# Копируем скрипт
COPY consumer.csx .

# Запускаем консьюмера
CMD ["dotnet-script", "consumer.csx"]
