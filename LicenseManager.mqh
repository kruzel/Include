//+------------------------------------------------------------------+
//|                                          Falcon License Manager
//|                                        Copyright 2025, Falcon EA
//+------------------------------------------------------------------+

#property copyright "Copyright 2025, Falcon EA"
#property strict

class CLicenseManager
{
private:
    string m_licenseKey;
    string m_hardwareId;
    datetime m_expiryDate;
    bool m_isActivated;
    
public:
    CLicenseManager()
    {
        m_isActivated = false;
        m_expiryDate = 0;
        m_hardwareId = GenerateHardwareId(); // Initialize hardware ID immediately
    }
    
    // Generate unique hardware fingerprint using only local MT4 data
    string GenerateHardwareId()
    {
        string hwid = "";
        
        // Use terminal-specific information that's hardware-related
        string dataPath = TerminalInfoString(TERMINAL_DATA_PATH);
        string commonPath = TerminalInfoString(TERMINAL_COMMONDATA_PATH);
        
        // Extract drive letters and path characteristics
        if(StringLen(dataPath) > 3)
        {
            hwid += StringSubstr(dataPath, 0, 1); // Drive letter
            hwid += IntegerToString(StringLen(dataPath));
        }
        
        if(StringLen(commonPath) > 3)
        {
            hwid += StringSubstr(commonPath, 0, 1); // Drive letter
            hwid += IntegerToString(StringLen(commonPath));
        }
        
        // Add terminal build and version info
        hwid += IntegerToString(TerminalInfoInteger(TERMINAL_BUILD));
        hwid += IntegerToString(TerminalInfoInteger(TERMINAL_MAXBARS));
        
        // Add some system characteristics
        hwid += IntegerToString(TerminalInfoInteger(TERMINAL_CPU_CORES));
        hwid += IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_PHYSICAL));
        hwid += IntegerToString(TerminalInfoInteger(TERMINAL_MEMORY_TOTAL));
        
        // Create a stable hash from the hardware string
        int hash1 = 7; // Prime number seed
        for(int i = 0; i < StringLen(hwid); i++)
        {
            hash1 = (hash1 * 31 + StringGetCharacter(hwid, i)) % 999999999;
        }
        
        // Create second hash for verification
        int hash2 = 11; // Another prime seed
        for(int i = StringLen(hwid) - 1; i >= 0; i--)
        {
            hash2 = (hash2 * 37 + StringGetCharacter(hwid, i)) % 999999999;
        }
        
        // Combine both hashes for final hardware ID
        return "FHWL" + IntegerToString(hash1) + "X" + IntegerToString(hash2);
    }
    
    // Validate license key format
    bool ValidateLicenseFormat(string licenseKey)
    {
        // Example format: FALCON-XXXXX-XXXXX-XXXXX-XXXXX
        if(StringLen(licenseKey) != 29) return false;
        if(StringSubstr(licenseKey, 0, 7) != "FALCON-") return false;
        
        // Check for proper dash positions at 6, 12, 18, and 24
        if(StringGetCharacter(licenseKey, 6) != '-' ||
           StringGetCharacter(licenseKey, 12) != '-' ||
           StringGetCharacter(licenseKey, 18) != '-' ||
           StringGetCharacter(licenseKey, 24) != '-') return false;
           
        return true;
    }
    
    // Advanced license validation with hardware binding
    bool ValidateLicenseAdvanced(string licenseKey, string hardwareId)
    {
        // Extract segments from license key
        string segment1 = StringSubstr(licenseKey, 7, 5);   // After FALCON-
        
        // Create validation hash from hardware ID
        int hwHash = 0;
        for(int i = 0; i < StringLen(hardwareId); i++)
        {
            hwHash = (hwHash * 31 + StringGetCharacter(hardwareId, i)) % 99999;
        }
        
        // Simple validation algorithm
        string expectedSegment = IntegerToString((hwHash * 7 + 12345) % 99999);
        while(StringLen(expectedSegment) < 5)
            expectedSegment = "0" + expectedSegment;
            
        // Check if first segment matches expected pattern
        return (segment1 == expectedSegment);
    }
    
    // Store license validation locally (simplified)
    bool StoreLicenseValidation(string licenseKey, string hardwareId)
    {
        string validationData = licenseKey + "|" + hardwareId + "|" + IntegerToString(TimeCurrent());
        
        string fileName = "FalconLicense.dat";
        int handle = FileOpen(fileName, FILE_WRITE|FILE_TXT);
        if(handle != INVALID_HANDLE)
        {
            FileWriteString(handle, validationData);
            FileClose(handle);
            return true;
        }
        
        return false;
    }
    
    // Validate stored license (simplified)
    bool ValidateStoredLicense(string licenseKey, string hardwareId)
    {
        string fileName = "FalconLicense.dat";
        
        if(!FileIsExist(fileName)) return false;
        
        int handle = FileOpen(fileName, FILE_READ|FILE_TXT);
        if(handle == INVALID_HANDLE) return false;
        
        string storedData = FileReadString(handle);
        FileClose(handle);
        
        string expectedData = licenseKey + "|" + hardwareId;
        
        // Check if stored data contains our expected data
        if(StringFind(storedData, expectedData) >= 0)
        {
            // Extract timestamp and check if not too old (30 days)
            int pipePos = StringFind(storedData, "|", StringFind(storedData, "|") + 1);
            if(pipePos > 0)
            {
                string timestampStr = StringSubstr(storedData, pipePos + 1);
                int timestamp = StrToInteger(timestampStr);
                if(TimeCurrent() - timestamp < 30 * 24 * 3600) // Valid for 30 days
                {
                    return true;
                }
            }
        }
        
        return false;
    }
    
    // Main license check function
    bool CheckLicense(string inputLicense = "")
    {
        m_hardwareId = GenerateHardwareId();
        
        // Try to get license from input or stored location
        if(inputLicense != "")
        {
            m_licenseKey = inputLicense;
        }
        else
        {
            // Try to read from file
            string fileName = "FalconKey.txt";
            if(FileIsExist(fileName))
            {
                int handle = FileOpen(fileName, FILE_READ|FILE_TXT);
                if(handle != INVALID_HANDLE)
                {
                    m_licenseKey = FileReadString(handle);
                    FileClose(handle);
                }
            }
        }
        
        if(!ValidateLicenseFormat(m_licenseKey))
        {
            Alert("Invalid license key format! Hardware ID: " + m_hardwareId);
            return false;
        }
        
        // Try advanced validation first, then stored validation
        if(!ValidateLicenseAdvanced(m_licenseKey, m_hardwareId))
        {
            if(!ValidateStoredLicense(m_licenseKey, m_hardwareId))
            {
                Alert("License validation failed! Hardware ID: " + m_hardwareId);
                return false;
            }
        }
        else
        {
            // Store successful validation
            StoreLicenseValidation(m_licenseKey, m_hardwareId);
        }
        
        m_isActivated = true;
        return true;
    }
    
    // Check if license is still valid
    bool IsLicenseValid()
    {
        if(!m_isActivated) return false;
        
        // Check expiry date if set
        if(m_expiryDate > 0 && TimeCurrent() > m_expiryDate)
        {
            m_isActivated = false;
            return false;
        }
        
        // Periodic hardware check (every 4 hours)
        static datetime lastHwCheck = 0;
        if(TimeCurrent() - lastHwCheck > 4 * 3600)
        {
            string currentHwId = GenerateHardwareId();
            if(currentHwId != m_hardwareId)
            {
                Alert("Hardware configuration changed! License may be invalid.");
                m_isActivated = false;
                return false;
            }
            lastHwCheck = TimeCurrent();
        }
        
        return true;
    }
    
    // Get trial period remaining days (hardware-based)
    int GetTrialDaysRemaining()
    {
        // Ensure hardware ID is generated
        if(m_hardwareId == "")
        {
            m_hardwareId = GenerateHardwareId();
        }
        
        // Create hardware-specific trial file name
        string hwShort = StringSubstr(m_hardwareId, 0, 8);
        string trialFile = "FalconTrial_" + hwShort + ".dat";
        
        if(!FileIsExist(trialFile))
        {
            // First run - create trial file
            Print("Creating new trial file: ", trialFile);
            int handle = FileOpen(trialFile, FILE_WRITE|FILE_TXT);
            if(handle != INVALID_HANDLE)
            {
                string trialData = m_hardwareId + "|" + IntegerToString(TimeCurrent());
                FileWriteString(handle, trialData);
                FileClose(handle);
                Print("Trial file created successfully. 7 days trial started.");
                return 7; // 7 day trial
            }
            else
            {
                Print("Failed to create trial file: ", trialFile);
                return 0;
            }
        }
        else
        {
            Print("Reading existing trial file: ", trialFile);
            int handle = FileOpen(trialFile, FILE_READ|FILE_TXT);
            if(handle != INVALID_HANDLE)
            {
                string storedData = FileReadString(handle);
                FileClose(handle);
                Print("Trial file data: ", storedData);
                
                // Verify trial data
                int pipePos = StringFind(storedData, "|");
                if(pipePos > 0)
                {
                    string expectedHwId = StringSubstr(storedData, 0, pipePos);
                    string timestampStr = StringSubstr(storedData, pipePos + 1);
                    int startTime = StrToInteger(timestampStr);
                    
                    Print("Expected HW ID: ", expectedHwId);
                    Print("Current HW ID: ", m_hardwareId);
                    
                    // Verify hardware ID matches
                    if(expectedHwId != m_hardwareId)
                    {
                        Print("Hardware ID mismatch! Trial invalid.");
                        return 0; // Trial invalid if hardware changed
                    }
                    
                    int daysUsed = (int)((TimeCurrent() - startTime) / 86400);
                    int remainingDays = MathMax(0, 7 - daysUsed);
                    Print("Days used: ", daysUsed, ", Remaining days: ", remainingDays);
                    return remainingDays;
                }
                else
                {
                    Print("Invalid trial file format");
                }
            }
            else
            {
                Print("Failed to read trial file: ", trialFile);
            }
        }
        
        return 0;
    }
    
    // Get hardware fingerprint for display/support
    string GetHardwareFingerprint()
    {
        // Ensure hardware ID is generated
        if(m_hardwareId == "")
        {
            m_hardwareId = GenerateHardwareId();
        }
        
        return m_hardwareId;
    }
    
    // Set license expiry date
    void SetExpiryDate(datetime expiryDate)
    {
        m_expiryDate = expiryDate;
    }
    
    // Check if license is about to expire
    bool IsLicenseExpiringSoon(int daysWarning = 7)
    {
        if(m_expiryDate <= 0) return false;
        
        int daysUntilExpiry = (int)((m_expiryDate - TimeCurrent()) / 86400);
        return (daysUntilExpiry <= daysWarning && daysUntilExpiry > 0);
    }
};
