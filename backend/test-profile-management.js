const axios = require("axios");

const BASE_URL = "http://localhost:4000/api";

// Test results tracking
let passed = 0;
let failed = 0;
const results = [];

function log(message, status = "INFO") {
    const timestamp = new Date().toISOString();
    const emoji = status === "PASS" ? "✅" : status === "FAIL" ? "❌" : "ℹ️";
    console.log(`${emoji} [${status}] ${message}`);
    results.push({ timestamp, status, message });
}

async function test(description, testFn) {
    try {
        await testFn();
        passed++;
        log(description, "PASS");
    } catch (error) {
        failed++;
        log(`${description}: ${error.message}`, "FAIL");
    }
}

async function runTests() {
    log("Starting Profile Management Tests");
    log("=".repeat(80));

    // Test users
    let citizenToken, moderatorToken, departmentToken;
    let citizenId, moderatorId, departmentId;

    // ============================================================
    // SETUP: Login as different users
    // ============================================================
    
    try {
        // Login as CITIZEN
        const citizenLogin = await axios.post(`${BASE_URL}/auth/login`, {
            email: "alice@example.com",
            password: "password123"
        });
        citizenToken = citizenLogin.data.token;
        citizenId = citizenLogin.data.user.id;
        log("Setup: CITIZEN login successful");

        // Login as MODERATOR
        const moderatorLogin = await axios.post(`${BASE_URL}/auth/login`, {
            email: "mod1@civicpulse.gov",
            password: "password123"
        });
        moderatorToken = moderatorLogin.data.token;
        moderatorId = moderatorLogin.data.user.id;
        log("Setup: MODERATOR login successful");

        // Login as DEPARTMENT
        const departmentLogin = await axios.post(`${BASE_URL}/auth/login`, {
            email: "water.dept@example.com",
            password: "password123"
        });
        departmentToken = departmentLogin.data.token;
        departmentId = departmentLogin.data.user.id;
        log("Setup: DEPARTMENT login successful");

    } catch (error) {
        log("Setup failed: " + error.message, "FAIL");
        process.exit(1);
    }

    log("=".repeat(80));

    // ============================================================
    // TEST 1: GET /api/auth/profile (CITIZEN)
    // ============================================================
    
    await test("GET /api/auth/profile - CITIZEN role", async () => {
        const res = await axios.get(`${BASE_URL}/auth/profile`, {
            headers: { Authorization: `Bearer ${citizenToken}` }
        });
        
        if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
        if (!res.data.user) throw new Error("No user in response");
        if (res.data.user.role !== "CITIZEN") throw new Error("Expected CITIZEN role");
        if (res.data.user.department_id !== null) throw new Error("CITIZEN should have null department_id");
        if (res.data.user.password) throw new Error("Password should not be returned");
        if (!res.data.user.createdAt) throw new Error("Missing createdAt");
        if (!res.data.user.updatedAt) throw new Error("Missing updatedAt");
    });

    // ============================================================
    // TEST 2: GET /api/auth/profile (MODERATOR)
    // ============================================================
    
    await test("GET /api/auth/profile - MODERATOR role", async () => {
        const res = await axios.get(`${BASE_URL}/auth/profile`, {
            headers: { Authorization: `Bearer ${moderatorToken}` }
        });
        
        if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
        if (res.data.user.role !== "MODERATOR") throw new Error("Expected MODERATOR role");
        if (res.data.user.department_id !== null) throw new Error("MODERATOR should have null department_id");
        if (res.data.user.password) throw new Error("Password should not be returned");
    });

    // ============================================================
    // TEST 3: GET /api/auth/profile (DEPARTMENT)
    // ============================================================
    
    await test("GET /api/auth/profile - DEPARTMENT role", async () => {
        const res = await axios.get(`${BASE_URL}/auth/profile`, {
            headers: { Authorization: `Bearer ${departmentToken}` }
        });
        
        if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
        if (res.data.user.role !== "DEPARTMENT") throw new Error("Expected DEPARTMENT role");
        if (!res.data.user.department_id) throw new Error("DEPARTMENT should have department_id");
        if (res.data.user.password) throw new Error("Password should not be returned");
    });

    // ============================================================
    // TEST 4: GET /api/auth/profile without JWT
    // ============================================================
    
    await test("GET /api/auth/profile - Missing JWT (401)", async () => {
        try {
            await axios.get(`${BASE_URL}/auth/profile`);
            throw new Error("Should have failed with 401");
        } catch (error) {
            if (error.response && error.response.status === 401) {
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 5: GET /api/auth/profile with invalid JWT
    // ============================================================
    
    await test("GET /api/auth/profile - Invalid JWT (401)", async () => {
        try {
            await axios.get(`${BASE_URL}/auth/profile`, {
                headers: { Authorization: "Bearer invalidtoken123" }
            });
            throw new Error("Should have failed with 401");
        } catch (error) {
            if (error.response && error.response.status === 401) {
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 6: PATCH /api/auth/profile - Update name
    // ============================================================
    
    await test("PATCH /api/auth/profile - Update name (CITIZEN)", async () => {
        const res = await axios.patch(`${BASE_URL}/auth/profile`, 
            { name: "Alice Updated" },
            { headers: { Authorization: `Bearer ${citizenToken}` }}
        );
        
        if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
        if (res.data.user.name !== "Alice Updated") throw new Error("Name not updated");
        if (res.data.user.role !== "CITIZEN") throw new Error("Role should remain CITIZEN");
    });

    // ============================================================
    // TEST 7: PATCH /api/auth/profile - Update email
    // ============================================================
    
    const newEmail = `alice.updated.${Date.now()}@example.com`;
    await test("PATCH /api/auth/profile - Update email (CITIZEN)", async () => {
        const res = await axios.patch(`${BASE_URL}/auth/profile`, 
            { email: newEmail },
            { headers: { Authorization: `Bearer ${citizenToken}` }}
        );
        
        if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
        if (res.data.user.email !== newEmail.toLowerCase()) throw new Error("Email not updated");
        if (res.data.user.role !== "CITIZEN") throw new Error("Role should remain CITIZEN");
    });

    // ============================================================
    // TEST 8: PATCH /api/auth/profile - Duplicate email
    // ============================================================
    
    await test("PATCH /api/auth/profile - Duplicate email (409)", async () => {
        try {
            await axios.patch(`${BASE_URL}/auth/profile`, 
                { email: "bob@example.com" }, // Existing user email
                { headers: { Authorization: `Bearer ${citizenToken}` }}
            );
            throw new Error("Should have failed with 409");
        } catch (error) {
            if (error.response && error.response.status === 409) {
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 9: PATCH /api/auth/profile - Invalid email format
    // ============================================================
    
    await test("PATCH /api/auth/profile - Invalid email format (400)", async () => {
        try {
            await axios.patch(`${BASE_URL}/auth/profile`, 
                { email: "not-an-email" },
                { headers: { Authorization: `Bearer ${citizenToken}` }}
            );
            throw new Error("Should have failed with 400");
        } catch (error) {
            if (error.response && error.response.status === 400) {
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 10: PATCH /api/auth/profile - Empty name
    // ============================================================
    
    await test("PATCH /api/auth/profile - Empty name (400)", async () => {
        try {
            await axios.patch(`${BASE_URL}/auth/profile`, 
                { name: "   " },
                { headers: { Authorization: `Bearer ${citizenToken}` }}
            );
            throw new Error("Should have failed with 400");
        } catch (error) {
            if (error.response && error.response.status === 400) {
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 11: PATCH /api/auth/profile - Empty email
    // ============================================================
    
    await test("PATCH /api/auth/profile - Empty email (400)", async () => {
        try {
            await axios.patch(`${BASE_URL}/auth/profile`, 
                { email: "   " },
                { headers: { Authorization: `Bearer ${citizenToken}` }}
            );
            throw new Error("Should have failed with 400");
        } catch (error) {
            if (error.response && error.response.status === 400) {
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 12: PATCH /api/auth/profile - Attempt to change role
    // ============================================================
    
    await test("PATCH /api/auth/profile - Attempt to change role (400)", async () => {
        try {
            await axios.patch(`${BASE_URL}/auth/profile`, 
                { name: "Alice", role: "MODERATOR" },
                { headers: { Authorization: `Bearer ${citizenToken}` }}
            );
            throw new Error("Should have failed with 400");
        } catch (error) {
            if (error.response && error.response.status === 400) {
                if (!error.response.data.message.includes("role")) {
                    throw new Error("Error message should mention 'role'");
                }
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 13: PATCH /api/auth/profile - Attempt to change department_id
    // ============================================================
    
    await test("PATCH /api/auth/profile - Attempt to change department_id (400)", async () => {
        try {
            await axios.patch(`${BASE_URL}/auth/profile`, 
                { name: "Water Dept", department_id: "507f1f77bcf86cd799439011" },
                { headers: { Authorization: `Bearer ${departmentToken}` }}
            );
            throw new Error("Should have failed with 400");
        } catch (error) {
            if (error.response && error.response.status === 400) {
                if (!error.response.data.message.includes("department_id")) {
                    throw new Error("Error message should mention 'department_id'");
                }
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 14: PATCH /api/auth/profile - Attempt to change password
    // ============================================================
    
    await test("PATCH /api/auth/profile - Attempt to change password (400)", async () => {
        try {
            await axios.patch(`${BASE_URL}/auth/profile`, 
                { name: "Alice", password: "newpassword" },
                { headers: { Authorization: `Bearer ${citizenToken}` }}
            );
            throw new Error("Should have failed with 400");
        } catch (error) {
            if (error.response && error.response.status === 400) {
                if (!error.response.data.message.includes("password")) {
                    throw new Error("Error message should mention 'password'");
                }
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 15: PATCH /api/auth/profile - No fields provided
    // ============================================================
    
    await test("PATCH /api/auth/profile - No fields provided (400)", async () => {
        try {
            await axios.patch(`${BASE_URL}/auth/profile`, 
                {},
                { headers: { Authorization: `Bearer ${citizenToken}` }}
            );
            throw new Error("Should have failed with 400");
        } catch (error) {
            if (error.response && error.response.status === 400) {
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 16: PATCH /api/auth/profile - Update both name and email
    // ============================================================
    
    const newEmail2 = `moderator.${Date.now()}@example.com`;
    await test("PATCH /api/auth/profile - Update both name and email (MODERATOR)", async () => {
        const res = await axios.patch(`${BASE_URL}/auth/profile`, 
            { name: "Moderator Updated", email: newEmail2 },
            { headers: { Authorization: `Bearer ${moderatorToken}` }}
        );
        
        if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
        if (res.data.user.name !== "Moderator Updated") throw new Error("Name not updated");
        if (res.data.user.email !== newEmail2.toLowerCase()) throw new Error("Email not updated");
        if (res.data.user.role !== "MODERATOR") throw new Error("Role should remain MODERATOR");
        if (res.data.user.department_id !== null) throw new Error("MODERATOR department_id should remain null");
    });

    // ============================================================
    // TEST 17: Verify DEPARTMENT profile update preserves department_id
    // ============================================================
    
    await test("PATCH /api/auth/profile - DEPARTMENT preserves department_id", async () => {
        // Get current profile
        const before = await axios.get(`${BASE_URL}/auth/profile`, {
            headers: { Authorization: `Bearer ${departmentToken}` }
        });
        const originalDeptId = before.data.user.department_id;
        
        // Update name
        const res = await axios.patch(`${BASE_URL}/auth/profile`, 
            { name: "Water Department Updated" },
            { headers: { Authorization: `Bearer ${departmentToken}` }}
        );
        
        if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
        if (res.data.user.name !== "Water Department Updated") throw new Error("Name not updated");
        if (res.data.user.role !== "DEPARTMENT") throw new Error("Role should remain DEPARTMENT");
        if (res.data.user.department_id !== originalDeptId) throw new Error("department_id should remain unchanged");
    });

    // ============================================================
    // TEST 18: PATCH /api/auth/profile - Missing JWT
    // ============================================================
    
    await test("PATCH /api/auth/profile - Missing JWT (401)", async () => {
        try {
            await axios.patch(`${BASE_URL}/auth/profile`, { name: "Test" });
            throw new Error("Should have failed with 401");
        } catch (error) {
            if (error.response && error.response.status === 401) {
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 19: PATCH /api/auth/profile - Invalid JWT
    // ============================================================
    
    await test("PATCH /api/auth/profile - Invalid JWT (401)", async () => {
        try {
            await axios.patch(`${BASE_URL}/auth/profile`, 
                { name: "Test" },
                { headers: { Authorization: "Bearer invalidtoken123" }}
            );
            throw new Error("Should have failed with 401");
        } catch (error) {
            if (error.response && error.response.status === 401) {
                return; // Expected
            }
            throw error;
        }
    });

    // ============================================================
    // TEST 20: Update with same email (should succeed)
    // ============================================================
    
    await test("PATCH /api/auth/profile - Update with same email (allowed)", async () => {
        const current = await axios.get(`${BASE_URL}/auth/profile`, {
            headers: { Authorization: `Bearer ${citizenToken}` }
        });
        const currentEmail = current.data.user.email;
        
        const res = await axios.patch(`${BASE_URL}/auth/profile`, 
            { email: currentEmail },
            { headers: { Authorization: `Bearer ${citizenToken}` }}
        );
        
        if (res.status !== 200) throw new Error(`Expected 200, got ${res.status}`);
        if (res.data.user.email !== currentEmail) throw new Error("Email should remain unchanged");
    });

    // ============================================================
    // RESULTS
    // ============================================================
    
    log("=".repeat(80));
    log(`PROFILE MANAGEMENT TESTS COMPLETE`);
    log(`Total Tests: ${passed + failed}`);
    log(`Passed: ${passed}`, passed === passed + failed ? "PASS" : "INFO");
    log(`Failed: ${failed}`, failed === 0 ? "PASS" : "FAIL");
    log("=".repeat(80));

    process.exit(failed > 0 ? 1 : 0);
}

runTests().catch(error => {
    log("Fatal error: " + error.message, "FAIL");
    console.error(error);
    process.exit(1);
});
