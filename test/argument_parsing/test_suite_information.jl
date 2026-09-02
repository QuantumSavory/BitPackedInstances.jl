
#==============================================================================#

# Dictionary format: flag => (tag, help text)
const test_suite_information = Dict(
	"--functionality" => (:functionality, "functionality test suite"),
	"--static_analysis" => (:static_analysis, "static analysis test suite")
	)

const all_tags = Set(
	(tag for (tag, _) in values(test_suite_information))
	)

#==============================================================================#
