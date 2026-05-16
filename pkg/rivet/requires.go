package rivet

import (
	"slices"

	"github.com/go-rivet/rivet/pkg/rivet/errors"
	"github.com/go-rivet/rivet/pkg/rivet/taskfile/ast"
)

// getMissingRequiredVars returns required vars that are not set in the task's vars.
func getMissingRequiredVars(t *ast.Task) []*ast.VarsWithValidation {
	if t.Requires == nil {
		return nil
	}
	var missing []*ast.VarsWithValidation
	for _, v := range t.Requires.Vars {
		if _, ok := t.Vars.Get(v.Name); !ok {
			missing = append(missing, v)
		}
	}
	return missing
}

func (e *Executor) areTaskRequiredVarsSet(t *ast.Task) error {
	missing := getMissingRequiredVars(t)
	if len(missing) == 0 {
		return nil
	}

	missingVars := make([]errors.MissingVar, len(missing))
	for i, v := range missing {
		missingVars[i] = errors.MissingVar{
			Name:          v.Name,
			AllowedValues: getEnumValues(v.Enum),
		}
	}

	return &errors.TaskMissingRequiredVarsError{
		TaskName:    t.Name(),
		MissingVars: missingVars,
	}
}

func (e *Executor) areTaskRequiredVarsAllowedValuesSet(t *ast.Task) error {
	if t.Requires == nil || len(t.Requires.Vars) == 0 {
		return nil
	}

	var notAllowedValuesVars []errors.NotAllowedVar
	for _, requiredVar := range t.Requires.Vars {
		varValue, _ := t.Vars.Get(requiredVar.Name)

		enumValues := getEnumValues(requiredVar.Enum)
		value, isString := varValue.Value.(string)
		if isString && len(enumValues) > 0 && !slices.Contains(enumValues, value) {
			notAllowedValuesVars = append(notAllowedValuesVars, errors.NotAllowedVar{
				Value: value,
				Enum:  enumValues,
				Name:  requiredVar.Name,
			})
		}
	}

	if len(notAllowedValuesVars) > 0 {
		return &errors.TaskNotAllowedVarsError{
			TaskName:       t.Name(),
			NotAllowedVars: notAllowedValuesVars,
		}
	}

	return nil
}

func getEnumValues(e *ast.Enum) []string {
	if e == nil {
		return nil
	}
	return e.Value
}
