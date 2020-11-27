/*
Package report provides helper structs/methods/funcs for formatting output

To format output for an array of structs:

	w := report.NewWriterDefault(os.Stdout)
	defer w.Flush()

	headers := report.Headers(struct {
		ID string
	}{}, nil)
	t, _ := report.NewTemplate("command name").Parse("{{range .}}{{.ID}}{{end}}")
	t.Execute(t, headers)
	t.Execute(t, map[string]string{
		"ID":"fa85da03b40141899f3af3de6d27852b",
	})
	// t.IsTable() == false

or

	w := report.NewWriterDefault(os.Stdout)
	defer w.Flush()

	headers := report.Headers(struct {
		CID string
	}{}, map[string]string{
		"CID":"ID"})
	t, _ := report.NewTemplate("command name").Parse("table {{.CID}}")
	t.Execute(t, headers)
	t.Execute(t,map[string]string{
		"CID":"fa85da03b40141899f3af3de6d27852b",
	})
	// t.IsTable() == true

Helpers:

	if report.IsJSON(cmd.Flag("format").Value.String()) {
		... process JSON and output
	}

and


Note: Your code should not ignore errors
*/
package report
