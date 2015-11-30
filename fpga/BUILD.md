

Сборка проекта проверена на версии САПР Quartus 14.0 и Quartus 15.0.
Для сборки проекта у вас должна быть установлена лицензионная версия Quartus 14.0 или новее.



# Сборка FPGA
 
 1. Распаковать архив с проектом или скачать последнею версия проекта из системы контроля версий (Github)
 2. Запустить Quartus GUI и открыть проект в созданной папке с исходниками (файл ethond.qpf)
 3. Запустить сборку проект с помощью кнопки "Start Compilation" или через опцию меню
 4. После окончания сборки в папке output_files/ будут созданы файлы ethond.sof и ethond.rbf
 5. Файл ethond.rbf используется в процессе загрузки SoC для конфигурирования firmware FPGA.
    Этот файл нужно перенести на microSD карту в директорию /lib/firmware/fpga (этот путь используется по умолчанию )


# Сборка Preloader/U-boot

 Предварительно требуется провести сборку и компиляции FPGA, так как часть нужных файлов появиться только на этапе Assembler'а.
 Дальнейшие действия проводятся в консольном режиме OS (запустить cmd.exe в Windows или установленный терминал в Linux)

 Требуется загрузить скрипт из каталога программы Quartus, который добавит в переменную PATH всё необходимое:

  1. Переходим в директорию hps_isw_handoff внутри папки с исходниками проекта (она будет создана после компиляции проекта)
     cd <путь до исходного проекта>/hps_isw_handoff

  2. Запустить сам скрипт из каталога программы Quartus 
     <путь до каталога программы Quartus>/embedded/embedded_command_shell.sh 
     Пример:
     /opt/altera/quartus14.0/embedded/embedded_command_shell.sh 


 ## Генерируем файлы для U-boot и Preloader:
    1. Выполнить следующую команду с указнными настройками:
       bsp-create-settings --type spl --bsp-dir build --preloader-settings-dir soc_ethond_hps_0    --settings build/settings.bsp --set spl.boot.WATCHDOG_ENABLE false
    
    2. Запустить команду для сборки Preloader:
       make -C build

    3. Запустить команду для сборки U-boot:
       make -C build uboot

    4. Запустить команду и сконвертировать переменные для U-boot в бинарный вид (используется файл настроек u-boot-env.txt из исходников проекта):
       ./build/uboot-socfpga/tools/mkenvimage -s 4096 -o u-boot-env.img  ../u-boot-env.txt



# После проведения всех действий будут получены следующие необходимые файлы

  output_files/ethond.rbf

  hps_isw_handoff/build/preloader-mkpimage.bin
  hps_isw_handoff/build/uboot-socfpga/u-boot.img
  hps_isw_handoff/u-boot-env.img
