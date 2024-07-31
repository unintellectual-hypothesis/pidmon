#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <unistd.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <csignal>
#include <cstdlib>

const std::string VM_PATH = "/proc/sys/vm/";
const std::string CFG_PATH = "/sdcard/Android/fog_mem_config.txt";
std::shared_ptr<std::string> highLoadThreshold = std::make_shared<std::string>("");
std::shared_ptr<std::string> mediumLoadThreshold = std::make_shared<std::string>("");
std::shared_ptr<std::string> swappinessChangeRate = std::make_shared<std::string>("");
bool swappinessOverHundred;


// 클린 셧다운을 위한 신호 처리기
inline void signalHandler(int signum)
{
    // 여기에서 필요한 정리를 수행합니다
    exit(signum);
}

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

// 문자열의 양쪽 끝에서 공백을 자르는 함수
std::string trim(const std::string &str) {
    size_t start = str.find_first_not_of(" \t\n\r");
    size_t end = str.find_last_not_of(" \t\n\r");
    if (start == std::string::npos || end == std::string::npos) {
        return "";
    }
    return str.substr(start, end - start + 1);
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
        char chmodCMD[1024];
        char echoCMD[1024];
        
        std::snprintf(chmodCMD, sizeof(chmodCMD), "chmod 0666 %s 2> /dev/null", filePath.c_str());
        std::snprintf(echoCMD, sizeof(echoCMD), "echo %s > %s", val.c_str(), filePath.c_str());

        executeCommand(chmodCMD);
        executeCommand(echoCMD);
    }

}

// 디바이스가 스왑을 지원하는지 테스트 > 100
inline void testSwappiness(bool& swappinessOverHundred)
{
    modValue("165", VM_PATH + "swappiness");
    std::ifstream swappinessPath(VM_PATH + "swappiness");
    int newSwappinessValue;
    swappinessPath >> newSwappinessValue;
    swappinessPath.close();
    swappinessOverHundred = (newSwappinessValue == 165);
}

// 스왑 및 VFS 캐시 압력을 동적으로 설정하는 기능
void startDynamicMemSystem()
{
    testSwappiness(swappinessOverHundred);
    bool swapfileOnly = (std::stoi(readConfig("zram_disksize")) == 0);

    // 기본값으로 구성에서 임계값 읽기
    *highLoadThreshold = readConfig("high_load_threshold");
    if (highLoadThreshold->empty()) {
        *highLoadThreshold = "65";
    }

    *mediumLoadThreshold = readConfig("medium_load_threshold");
    if (mediumLoadThreshold->empty()) {
        *mediumLoadThreshold = "25";
    }

    *swappinessChangeRate = readConfig("swappiness_change_rate");
    if (swappinessChangeRate->empty()) {
        *swappinessChangeRate = "10";
    }

    while(true)
    {
        std::string displayState = trim(getCommandOutput("dumpsys display | awk -F '=' '/mScreenState/ {print $2}'"));
        if(displayState == "OFF")
        {
            sleep(std::stoi(*swappinessChangeRate));
        }
        else
        {
            // /proc/loadavg의 첫 번째 열을 읽습니다
            std::ifstream loadavgFilePath("/proc/loadavg");
            double loadAvg;
            loadavgFilePath >> loadAvg;
            loadavgFilePath.close();

            int loadValue = static_cast<int>(loadAvg * 100 / 8);

            std::string newSwappiness;
            std::string newCachePressure;

            if (swapfileOnly)
            {
                executeCommand("resetprop -n ro.lmk.use_minfree_levels false");
            }

            if (loadValue > std::stoi(*highLoadThreshold))
            {
                if (swapfileOnly)
                {
                    newSwappiness = "40";
                    newCachePressure = "180";
                }
                else
                {
                    executeCommand("resetprop -n ro.lmk.use_minfree_levels false");
                    if (swappinessOverHundred)
                    {
                        newSwappiness = "100";
                        newCachePressure = "175";
                    }
                    else
                    {
                        newSwappiness = "85";
                        newCachePressure = "175";
                    }
                }

            }
            else if (loadValue > std::stoi(*mediumLoadThreshold))
            {
                if (swapfileOnly)
                {
                    newSwappiness = "60";
                    newCachePressure = "150";
                }
                else
                {
                    executeCommand("resetprop -n ro.lmk.use_minfree_levels true");
                    if (swappinessOverHundred)
                    {
                        newSwappiness = "150";
                        newCachePressure = "140";
                    }
                    else
                    {
                        newSwappiness = "90";
                        newCachePressure = "140";
                    }
                }
            }
            else
            {
                if (swapfileOnly)
                {
                    newSwappiness = "85";
                    newCachePressure = "120";                    
                }
                else
                {
                    executeCommand("resetprop -n ro.lmk.use_minfree_levels true");
                    if (swappinessOverHundred)
                    {
                        newSwappiness = "165";
                        newCachePressure = "110";
                    }
                    else
                    {
                        newSwappiness = "100";
                        newCachePressure = "110";
                    }
                }
            }

            modValue(newSwappiness, VM_PATH + "swappiness");
            modValue(newCachePressure, VM_PATH + "vfs_cache_pressure");

            // 오버헤드를 줄이기 위해 동적 스왑 및 VFS 캐시 압력의 간격을 설정합니다
            sleep(std::stoi(*swappinessChangeRate));
        }
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

    startDynamicMemSystem();

    exit(EXIT_SUCCESS);
}