# Скрипт для копирования сетевых директорий с удаленого сервера на сервер с которого запускается данный скрип. Скрипт копирует сетевые директории и права доступа к ним, а также иерархию директорий с NTFS правами.
# Данный скрипт копирует иерархию директорий, но не копирует сами файлы. Для копирования файлов необходимо добавить соответствующие ключи в модуль robocopy.
# Данный скрипт даптирован для копирования сетевых директорий с серверов маркета, т.к. имеет проверку по именам шар "$remoteShare.Name -like...". Если есть необходимость использования скрипта в других сценариях, то необходимо адаптировать проверку под свои условия.

# V1.1 - Добавлена проверка наличия сетевой директории на локальном компьютере
# V1.2 - Добавлена проверка успешности копирования директории на локальный компьютер, а также предупреждение о наличии ошибок при выполнении скрипта
# V1.3 - Добавлен вывод назначений прав на объект  

$serverName = read-host 'Введите имя сервера с которого необходимо скопировать сетевые директории'
$remoteShares = Get-SmbShare -CimSession $serverName #Получаем список шар на удаленном сервере
$error_flag = $false
# Write-Output $remoteShares.Name

# Обрабатываем каждую директорию отдельно
foreach ($remoteShare in $remoteShares) {  

    # Фильтруем сетевые директории по ключевым фразам, которые должны содержаться их в именах  
    if ( $remoteShare.Name -like '*pocketbot*' -Or $remoteShare.Name -like '*repl*' -Or $remoteShare.Name -like '*market*' ) { 

            # Проверяем и копируем отсутствующие директории
            if (-not (Test-Path -Path $remoteShare.Path)) {
                Write-Host -fore Yellow 'Копирую директорию' $remoteShare.Path 'на локальный компьютер...'
                $remotePath = "\\$serverName\" + $remoteShare.Name
                $localPath = $remoteShare.Path
                robocopy $remotePath $localPath /COPY:S /E /IS /DCOPY:T

                # Проверка успешности копирования директории
                if ( Test-Path -Path $remoteShare.Path ) { Write-Host -fore Green 'Директория' $remoteShare.Path 'успешно скопирована на локальный компьютер!'
                } else { 
                    Write-Host -fore Red 'Директория' $remoteShare.Path 'не была скопирована на локальный компьютер! Проверьте ошибки выполнения модуля robocopy.' 
                    $error_flag = $true
                        }
            } else { Write-Host -fore Green 'Директория' $remoteShare.Path 'уже существует на локальном компьютере! Никаких действий не требуется.' }

            # Получаем информацию о доступах к сетевым директориям на удаленном компьютере
            $remoteShareAccessList = Get-SmbShareAccess -Name $remoteShare.Name -CimSession $serverName
            
            # Получаем список сетевых директорий на локальном компьютере
            $localShareList = Get-SmbShare

            # Проверяем наличие такой же сетевой директории на локальном компьютере
            $flag = $false
            foreach ($localShare in $localShareList.Name) {
                if ( $localShare -eq $remoteShare.Name ) { $flag = $true }
            }
   

            if ( $flag -eq $true ) { Write-Host -fore Green 'Сетевая директория' $remoteShare.Name 'уже существует на локальном компьютере! Никаких действий не требуется.'
            } else { 
                    if (-not (Test-Path -Path $remoteShare.Path)) {
                        Write-Host -fore Red 'Сетевая директория' $remoteShare.Name 'не создана на локальном компьютере по причине отсутствия директории' $remoteShare.Path
                        $error_flag = $true
                    } else {
                        # Создаем такую же сетевую директорию на локальномм компьютере
                        Write-Host -fore Yellow 'Создаю сетевую директорию' $remoteShare.Name 'на локальном компьютере и назначаю права:'
                        New-SmbShare -Name $remoteShare.Name -Path $remoteShare.Path | Out-Null
                
                        # Отдельно берем каждый объект с правами на сетевую директорию и задаем такой же на локальную директорию      
                        foreach ($remoteShareAccess in $remoteShareAccessList) {                        
                            Grant-SmbShareAccess -Name $remoteShareAccess.Name -AccountName $remoteShareAccess.AccountName -AccessRight $remoteShareAccess.AccessRight -Force | Out-Null
                            Write-Host -fore Yellow 'Назначаю права' $remoteShareAccess.AccessRight 'объекту' $remoteShareAccess.AccountName
                        }
                    
                    
                    Write-Host -fore Green 'Сетевая директория' $remoteShare.Name 'успешно создана на локальном компьютере!'

                    }
 
              }
            
    Write-Host '==================================================================================='

    }

}

if ($error_flag -eq $true) { Write-Host -fore Red 'ВНИМАНИЕ! ПРИ ВЫПОЛНЕНИИ СКРИПТА БЫЛИ ОБНАРУЖЕНЫ ОШИБКИ, ПРОВЕРЬТЕ ВЫВОД!' }