#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <vector>
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>

const std::string ZRAM_SYS = "/sys/block/zram0/";
const std::string CFG_PATH = "/sdcard/Android/fog_mem_config.txt";

// 안드로이드 셸을 실행하는 함수입니다.
void executeCommand(const char* command)
{
    pid_t pid = fork();

    if (pid == -1) {
        // 오류 포크
        perror("fork");
        exit(EXIT_FAILURE);
    } else if (pid == 0) {
        // 하위 프로세스
        execlp("/system/bin/sh", "su", "-c", command, (char*)NULL);
        // execlp가 반환되면 오류가 발생했습니다.
        perror("execlp");
        exit(EXIT_FAILURE);
    } else {
        // 상위 프로세스
        int status;
        waitpid(pid, &status, 0);
    }
}

// 문자열의 양쪽 끝에서 공백을 자르는 함수
std::string trim(const std::string &str) {
    size_t start = str.find_first_not_of(" \t\n\r");
    size_t end = str.find_last_not_of(" \t\n\r");
    if (start == std::string::npos || end == std::string::npos) {
        return "";
    }
    return str.substr(start, end - start + 1);
}

// 셸 명령에서 출력 가져오기
std::string getCommandOutput(const std::string &command)
{
    int pipefd[2];
    if (pipe(pipefd) == -1) {
        perror("pipe");
        return "";
    }

    pid_t pid = fork();
    if (pid == -1) {
        perror("fork");
        return "";
    }

    if (pid == 0) {
        close(pipefd[0]);
        dup2(pipefd[1], STDOUT_FILENO);
        close(pipefd[1]);

        execl("/system/bin/sh", "su", "-c", command.c_str(), nullptr);
        perror("execl");
        _exit(EXIT_FAILURE);
    } else {
        close(pipefd[1]);

        std::vector<char> buffer(4096);
        ssize_t count;
        std::string result;
        while ((count = read(pipefd[0], buffer.data(), buffer.size())) > 0) {
            result.append(buffer.data(), count);
        }
        close(pipefd[0]);

        int status;
        waitpid(pid, &status, 0);

        return result;
    }
}

// 클린 셧다운을 위한 신호 처리기
inline void signalHandler(int signum)
{
    // 여기에서 필요한 정리를 수행합니다
    exit(signum);
}

// 구성 파일에서 값 읽기
std::string readConfig(const std::string& key)
{
    std::ifstream configFile(CFG_PATH);
    std::string line;
    while (std::getline(configFile, line)) {
        std::size_t pos = line.find('=');
        if (pos != std::string::npos) {
            std::string currentKey = line.substr(0, pos);
            std::string value = line.substr(pos + 1);
            if (currentKey == key) {
                configFile.close();
                return value;
            }
        }
    }

    configFile.close();
    return "";
}

// 파일 존재 여부 확인
inline bool fileExists(const std::string& fileNamePath)
{
    struct stat buffer;
    return (stat (fileNamePath.c_str(), &buffer) == 0 && !(buffer.st_mode & S_IFDIR));
}

// 시스템 값 수정
void modValue(const std::string& val, const std::string& filePath)
{
    if(fileExists(filePath))
    {
        char chmodCMD[4096];
        char echoCMD[4096];
        
        std::snprintf(chmodCMD, sizeof(chmodCMD), "chmod 0666 %s 2> /dev/null", filePath.c_str());
        std::snprintf(echoCMD, sizeof(echoCMD), "echo %s > %s", val.c_str(), filePath.c_str());

        executeCommand(chmodCMD);
        executeCommand(echoCMD);
    }

}

bool zramWritebackSupport()
{
    return (fileExists(ZRAM_SYS + "writeback") && fileExists(ZRAM_SYS + "backing_dev"));
}


// 자동 ZRAM 쓰기백 시작
void startAutoZRAMwriteback() {
    int appSwitchThreshold = std::stoi(readConfig("app_switch_threshold"));
    if (appSwitchThreshold == 0) appSwitchThreshold = 10;

    int ZRAMwritebackRate = std::stoi(readConfig("ZRAMwritebackRate"));
    if (ZRAMwritebackRate == 0) ZRAMwritebackRate = 10;

    int WRITEBACK_NUM = 0;
    std::string CURRENT_APP;
    int appSwitch = 0;

    while (true) {
        std::string PREV_APP = trim(getCommandOutput("dumpsys activity lru | grep 'TOP' | awk 'NR==1' | awk -F '[ :/]+' '{print $7}'"));
        
        int memTotal = std::stoi(trim(getCommandOutput("awk '/^MemTotal:/{print $2}' /proc/meminfo")));
        int memAvail = std::stoi(trim(getCommandOutput("awk '/^MemAvailable:/{print $2}' /proc/meminfo")));
        int minMemAvail = memTotal / 5;

        if (memAvail <= minMemAvail) {
            std::string displayState = trim(getCommandOutput("dumpsys display | awk -F '=' '/mScreenState/ {print $2}'"));
            
            if (displayState == "OFF") {
                modValue("all", ZRAM_SYS + "idle");
                modValue("idle", ZRAM_SYS + "writeback");
                appSwitch = 0;
            }
        }

        if (PREV_APP != CURRENT_APP) {
            if (!(PREV_APP.empty())) {
                appSwitch++;
            }
        }

        if (appSwitch > appSwitchThreshold) {
            std::string displayState = trim(getCommandOutput("dumpsys display | awk -F '=' '/mScreenState/ {print $2}'"));

            if (WRITEBACK_NUM > 5) {
                WRITEBACK_NUM = 0;
            }

            if (WRITEBACK_NUM == 5 && displayState == "OFF") {
                modValue("all", ZRAM_SYS + "idle");
                modValue("idle", ZRAM_SYS + "writeback");
                WRITEBACK_NUM++;
                appSwitch = 0;
            } else {
                if (WRITEBACK_NUM < 4) {
                    modValue("huge", ZRAM_SYS + "writeback");
                    WRITEBACK_NUM++;
                    appSwitch = 0;
                }
            }
        }

        CURRENT_APP = PREV_APP;
        sleep(ZRAMwritebackRate);
    }
}

int main() {
    pid_t pid, sid;

    pid = fork();

    if (pid < 0) {
        exit(EXIT_FAILURE);
    }

    if (pid > 0) {
        exit(EXIT_SUCCESS);
    }

    umask(0);

    sid = setsid();
    if (sid < 0) {
        exit(EXIT_FAILURE);
    }

    if ((chdir("/")) < 0) {
        exit(EXIT_FAILURE);
    }

    close(STDIN_FILENO);
    close(STDOUT_FILENO);
    close(STDERR_FILENO);

    signal(SIGTERM, signalHandler);

    startAutoZRAMwriteback();

    exit(EXIT_SUCCESS);
}
